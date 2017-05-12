use strict;
package Mariachi;
use Email::Thread;
use Template;
use Time::HiRes qw( gettimeofday tv_interval );
use Storable qw( store retrieve );
use File::Path qw( mkpath );
use File::Copy qw( copy move );
use File::Find::Rule;
use File::Basename;
use base qw( Class::Accessor::Fast );
our $VERSION = '0.52';

__PACKAGE__->mk_accessors( qw( config messages rootset
                               start_time last_time tt ) );

=head1 NAME

Mariachi - all dancing mail archive generator

=head1 DESCRIPTION

=head1 ACESSORS

=head2 ->config

An L<AppConfig> object containing the current configuration.  See
L<mariachi> for details of the configurable items.

=head2 ->messages

The current set of messages

=head2 ->rootset

The rootset of threaded messages

=head2 ->start_time

=head2 ->last_time

Used internally by the C<_bench> method


=head1 METHODS

All of these are instance methods, unless stated.

=head2 ->new( %initial_values )

your general class-method constructor

=cut

sub new {
    my $class = shift;
    $class->SUPER::new({@_});
}

sub _bench {
    my $self = shift;
    my $message = shift;

    my $now = [gettimeofday];
    my $start = $self->start_time;
    my $last  = $self->last_time || $now;
    $start = $self->start_time($now) unless $start;

    printf "%-50s %.3f elapsed %.3f total\n",
      $message, tv_interval( $last, $now ), tv_interval( $start, $now );

    $self->last_time($now);
}

=head2 ->load

populate C<messages> from C<input>

=cut

sub load {
    my $self = shift;

    my $folder = Mariachi::Folder->new( $self->config->input )
      or die "Unable to open ".$self->config->input;

    $| = 1;
    my $cache;
    $cache = $self->config->input.".cache" if $ENV{M_CACHE};
    if ($cache && -e $cache && !$self->config->refresh) {
        print "pulling in $cache\n";
        $self->messages( retrieve( $cache ) );
        return;
    }

    my $count = 0;
    my @msgs;
    while (my $msg = $folder->next_message) {
        push @msgs, $msg;
        print STDERR "\r$count messages" if ++$count % 100 == 0;
    }
    print STDERR "\n";

    if ($cache) {
        print "caching\n";
        store( \@msgs, $cache );
    }

    $self->messages( \@msgs );
}

=head2 ->dedupe

remove duplicates from C<messages>

=cut

sub dedupe {
    my $self = shift;

    my (%seen, @new, $dropped);
    $dropped = 0;
    for my $mail (@{ $self->messages }) {
        my $msgid = $mail->header('message-id');
        if ($seen{$msgid}++) {
            $dropped++;
            next;
        }
        push @new, $mail;
    }
    print "dropped $dropped duplicate messages\n";
    $self->messages(\@new);
}

=head2 ->sanitise

some messages have been near mail2news gateways, which means that some
message ids in the C<references> and C<in-reply-to> headers get munged
like so: <$group/$message_id>

fix this in C<messages>

=cut

sub sanitise {
    my $self = shift;

    for my $mail (@{ $self->messages }) {
        for (qw( references in_reply_to )) {
            my $hdr = $mail->header($_) or next;
            my $before = $hdr;
            $hdr =~ s{<[^>]*?/}{<}g or next;
            #print "$_ $before$_: $hdr";
            $mail->header_set($_, $hdr);
        }
    }
}

=head2 ->thread

populate C<rootset> with an Email::Thread::Containers created from
C<messages>

=cut

# the Fisher-Yates shuffle from perlfaq4
sub _shuffle {
    my $array = shift;
    my $i;
    for ($i = @$array; --$i; ) {
        my $j = int rand ($i+1);
        @$array[$i,$j] = @$array[$j,$i];
    }
}

sub thread {
    my $self = shift;
    #_shuffle $self->messages;
    my $threader = Email::Thread->new( @{ $self->messages } );
    $threader->thread;
    $self->rootset( [ grep { $_->topmost } $threader->rootset ] );
}

=head2 ->order

order C<rootset> by date

=cut

sub order {
    my $self = shift;

    my @rootset = @{ $self->rootset };
    $_->order_children(
        sub {
            sort {
                eval { $a->topmost->message->epoch_date } <=>
                eval { $b->topmost->message->epoch_date }
              } @_
          }) for @rootset;

    # we actually want the root set to be ordered latest first
    @rootset = sort {
        $b->topmost->message->epoch_date <=> $a->topmost->message->epoch_date
    } @rootset;

    # And optionally reverse the order
    @rootset = reverse(@rootset)
      if $self->config->reverse;

    $self->rootset( \@rootset );
}

=head2 ->sanity

(in)sanity test - check everything in C<messages> is reachable when
walking C<rootset>

=cut

sub sanity {
    my $self = shift;

    my %mails = map { $_ => $_ } @{ $self->messages };
    my $count;
    my $check = sub {
        my $cont = shift or return;
        my $mail = $cont->message or return;
        ++$count;
        #print STDERR "\rverify $count";
        delete $mails{ $mail || '' };
    };
    $_->iterate_down( $check ) for @{ $self->rootset };
    undef $check;
    #print STDERR "\n";

    return unless %mails;
    die "\nDidn't see ".(scalar keys %mails)." messages";
    print join "\n", map {
        my @ancestors;
        my $x = $_->container;
        my %seen;
        my $last;
        while ($x) {
            if ($seen{$x}++) { push @ancestors, "$x ancestor loop!\n"; last }
            my $extra = $x->{id};
            $extra .= " one-way"
              if $last && !grep { $last == $_ } $x->children;
            push @ancestors, $x." $extra";
            $last = $x;
            $x = $x->parent;
        }
        $_->header("message-id"), @ancestors
    } values %mails;

}

=head2 ->strand

run a strand through all C<messages> - wander over C<threader> setting
the Message ->next and ->prev links

=cut

sub strand {
    my $self = shift;

    my $prev;
    for my $root (@{ $self->rootset }) {
        my $sub = sub {
            my $mail = $_[0]->message or return;
            $prev->next($mail) if $prev;
            $mail->prev($prev);
            $mail->root($root);
            $prev = $mail;
        };

        $root->iterate_down( $sub );
        undef $sub;
    }
}

=head2 ->split_deep

wander over C<rootset> reparenting subthreads that are
considered too deep

=cut

sub split_deep {
    my $self = shift;

    my @toodeep;
    for my $root (@{ $self->rootset }) {
        my $sub = sub {
            my ($cont, $depth) = @_;

            # only note first entries
            if ($depth && ($depth % 6 == 0)
                && $cont->parent->child == $cont) {
                push @toodeep, $cont;
            }
        };

        $root->iterate_down( $sub );
        undef $sub;
    }

    print "splicing threads in ", scalar @toodeep, " places\n";
    for (@toodeep) {
        # the top one needs to be empty, because we're cheating.
        # to keep references straight, we'll move its content
        my $top = $_->topmost;
        my $root = $top->message->root or die "batshit!";
        if ($root->message) {
            my $new = Mail::Thread::Container->new($root->messageid);
            $root->messageid('dummy');
            $new->message($root->message);
            $root->message(undef);
            $new->child($root->child);
            $root->child($new);
            $root = $new;
        }
        $root->add_child( $_ );
    }
}


=head2 ->copy_files

copy files into the output dir

=cut


sub copy_files {
    my $self = shift;

    for my $dir (@{ $self->config->templates }) {
        my @files = map {
            s{$dir/?}{}; $_
        } find( or => [ find( directory =>
                              name      => [ qw( CVS .svn ) ],
                              prune     =>
                              discard   => ),
                        find( file => '!name' => [ '*.tt2', '*~', '*.bak' ] )
                       ],
                in => $dir );
        for (@files) {
            mkpath dirname $self->config->output . "/$_";
            copy( "$dir/$_", $self->config->output . "/$_" )
              or die "couldn't copy $dir/$_ $!";
        }
    }
}


=head2 init_tt

=cut

sub init_tt {
    my $self = shift;

    $self->tt(
        Template->new(
            INCLUDE_PATH => join(':', reverse @{ $self->config->templates }),
            RECURSION => 1
           )
       );
}


=head2 generate_pages( $template, $filename, %data )

=cut

sub nthpage {
    my $self = shift;
    my $n    = shift;
    my $page = shift;
    return $page if $n == 1;
    --$n;
    $page =~ s/\./_$n./;
    return $page;
}

sub generate_pages {
    my $self = shift;
    my $template = shift;
    my $spool    = shift;

    my $again;
    do {
        my $file = $spool;
        $self->tt->process(
            $template,
            { @_,
              mariachi  => $self,
              spool     => $spool,
              # callbacktastic
              nthpage   => sub { $self->nthpage( shift, $spool ) },
              again     => sub { $again },
              file      => sub { $file  },
              set_again => sub { $again = shift; return },
              set_file  => sub { $file  = shift; return }, },
            $self->config->output . "/$$.tmp" )
          or die $self->tt->error;

        mkpath dirname $self->config->output . "/$file";
        move $self->config->output . "/$$.tmp", $self->config->output . "/$file"
          or die "$!";
    } while $again;
}


=head2 ->generate_lurker_index

=cut

sub generate_lurker {
    my $self = shift;

    return unless $self->config->lurker;

    my $l = Mariachi::Lurker->new;
    $self->generate_pages(
        'lurker.tt2', 'lurker.html',
        content => [
            map { [ $l->arrange( $_ ) ] } @{ $self->rootset }
           ],
        perpage    => 10,
       );
}


=head2 ->generate_thread

=cut

sub generate_thread {
    my $self = shift;

    $self->generate_pages(
        'index.tt2', 'index.html',
        content => $self->rootset,
        perpage => 20,
    );
}


=head2 ->generate_date

=cut

sub generate_date {
    my $self = shift;

    my %touched_dates;
    my %dates;

    # wander things to find dirty threads, and dates
    for my $root (@{ $self->rootset }) {
        my $sub;
        $sub = sub {
            my $c = shift or return;

            if (my $mail = $c->message) {
                # mark the thread dirty, if the message is new
                unless (-e $self->config->output."/".$mail->filename &&
                        !$self->config->refresh) {
                    # dirty up the date indexes
                    $touched_dates{ $mail->year } = 1;
                    $touched_dates{ $mail->month } = 1;
                    $touched_dates{ $mail->day } = 1;
                }

                # add things to the date indexes
                push @{ $dates{ $mail->year } }, $mail;
                push @{ $dates{ $mail->month } }, $mail;
                push @{ $dates{ $mail->day } }, $mail;
            }
        };
        $root->iterate_down($sub);
        undef $sub; # since we closed over ourself, we'll have to be specific
    }

    for ( keys %touched_dates ) {
        my @mails = sort {
            $a->epoch_date <=> $b->epoch_date
        } @{ $dates{$_} };

        my @depth = split m!/!;
        $self->generate_pages( 'date.tt2', "$_/index.html",
                               archive_date => $_,
                               content      => \@mails,
                               base         => "../" x @depth,
                               perpage      => 20,
                              );
    }
}

=head2 ->generate_bodies

render thread tree into the directory of C<output>

=cut

sub generate_bodies {
    my $self = shift;

    my %touched_threads;
    # wander things to find dirty threads
    for my $root (@{ $self->rootset }) {
        my $sub;
        $sub = sub {
            if (my $mail = eval { $_[0]->message }) {
                # mark the thread dirty, if the message is new
                $touched_threads{ $root } = $root
                  unless -e $self->config->output."/".$mail->filename
                    && !$self->config->refresh;
            }
        };
        $root->iterate_down($sub);
        undef $sub; # since we closed over ourself, we'll have to be specific
    }

    # figure out adjacent dirty threads
    my @threads = @{ $self->rootset };
    for my $i (grep { $touched_threads{ $threads[$_] } } 0..$#threads) {
        $touched_threads{ $threads[$i-1] } = $threads[$i-1] if $i > 0;
        $touched_threads{ $threads[$i+1] } = $threads[$i+1] if $i+1 < @threads;
    }

    # and then render all the messages in the dirty threads
    my $count  = 0;
    my $tt = $self->tt;
    for my $root (values %touched_threads) {
        my $sub = sub {
            my $mail = $_[0]->message or return;
            print STDERR "\rmessage $count" if ++$count % 100 == 0;

            $tt->process('message.tt2',
                         { base      => '../../../',
                           mariachi  => $self,
                           thread    => $root,
                           message   => $mail,
                           container => $_[0],
                         },
                         $self->config->output . "/" . $mail->filename)
              or die $tt->error;
        };
        $root->recurse_down( $sub );
        undef $sub;
    }
    print STDERR "\n";
}

=head2 ->perform

do all the right steps

=cut

sub perform {
    my $self = shift;

    $self->_bench("reticulating splines");
    $self->load;            $self->_bench("load ".scalar @{ $self->messages });
    $self->dedupe;          $self->_bench("dedupe");
    #$self->sanitise;        $self->_bench("sanitise");
    $self->thread;          $self->_bench("thread");
    $self->sanity;          $self->_bench("sanity");
    $self->order;           $self->_bench("order");
    $self->sanity;          $self->_bench("sanity");
    $self->copy_files;      $self->_bench("copy files");
    $self->init_tt;         $self->_bench("tt init");
    $self->generate_lurker; $self->_bench("lurker output");
    $self->strand;          $self->_bench("strand");
    $self->split_deep;      $self->_bench("deep threads split up");
    $self->sanity;          $self->_bench("sanity");
    $self->order;           $self->_bench("order");
    $self->generate_thread; $self->_bench("regular thread indexes");
    $self->generate_date;   $self->_bench("date indexes");
    $self->generate_bodies; $self->_bench("messages");
}

package Mariachi::Folder;
use Mariachi::Message;
use Email::Folder;
use base 'Email::Folder';

sub bless_message { Mariachi::Message->new($_[1]) }

package Mariachi::Lurker;
use Mail::Thread::Chronological;
use base 'Mail::Thread::Chronological';

sub extract_time { $_[1]->message->epoch_date }

1;

__END__

=head1 AUTHORS

This code was written as part of the Siesta project and includes code
from:

Richard Clamp <richardc@unixbeard.net>

Simon Wistow <simon@thegestalt.org>

Tom Insam <tom@jerakeen.org>

Mark Fowler <mark@twoshortplanks.com>

More information about the Siesta project can be found online at
http://siesta.unixbeard.net/

=head1 COPYRIGHT

Copyright 2003 The Siesta Project

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

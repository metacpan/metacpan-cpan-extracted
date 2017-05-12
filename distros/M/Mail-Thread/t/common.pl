use strict;
BEGIN { eval "use Mail::Internet;";
    if ($@) {
        require Test::More;
        Test::More->import(skip_all =>"You don't have Mail::Internet");
        exit;
    }
    eval "use Test::Differences";
}

package Email::Abstract::Mail;
use base 'Email::Abstract::MailInternet';
# keep a sequence number so we can order things later
package Mail;
use base 'Mail::Internet';
sub order { $_[0]->{___order} }
my $seq;
sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    # hacky
    $self->{___order} = ++$seq;
    return $self;
}

package main;

sub slurp_messages {
    my $mbox = shift;
    open FH, $mbox or return;
    my @messages;
    my @lines;
    while (<FH>) {
        if (/^From / && @lines) {
            my $mail = Mail->new(\@lines);
            push @messages, $mail;
            @lines = ();
        }
        push @lines, $_;
    }
    return @messages, Mail->new(\@lines);
}

sub dump_into {
    my $threader = shift;
    my $ref      = shift;

    $threader->order(sub {
                         sort { eval { $a->topmost->message->order } <=>
                                eval { $b->topmost->message->order } } @_;
                     });

    $_->iterate_down(
        sub {
            my ($self, $level) = @_;
            push @$ref,
              [ $level, $self->message ? $self->subject : "[ Message not available ]",
                $self->{id} ];
        }) for $threader->rootset;
}

# a beefed up is_deeply
sub deeply ($$;$) {
    goto &eq_or_diff if defined &eq_or_diff;
    goto &is_deeply;
}

1;

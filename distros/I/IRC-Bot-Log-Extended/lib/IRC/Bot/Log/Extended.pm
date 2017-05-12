package IRC::Bot::Log::Extended;

use Moose;
use Carp 'croak';

our $VERSION = '0.03';
our $AUTHORITY = 'cpan:FAYLAND';

extends 'IRC::Bot::Log';

has 'split_channel' => ( is => 'rw', isa => 'Bool', default => 1 );
has 'split_day'     => ( is => 'rw', isa => 'Bool', default => 1 );
has 'Path'          => ( is => 'rw', isa => 'Str' );

override 'chan_log' => sub {
    my ( $self, $message ) = @_;

    if ( $self->{'Path'} ne 'null' ) {
        
        my $split_channel = $self->split_channel;
        my $split_day     = $self->split_channel;

        my $name = 'channel';
        if ( $split_channel ) {
            # [#moose 21:40] 
            my ($channel) = ( $message =~ /^\[\#(\S+)\s+/is );
            $name = $channel;
        }
        if ( $split_day ) {
            # get today
            my @atime = localtime();
            my $today = sprintf("%04d%02d%02d", $atime[5] + 1900, $atime[4] + 1, $atime[3]);
            $name .= "_$today"; 
        }
        my $file = $self->{'Path'} . $name . '.log';

        $self->pre_insert( \$file, \$message );
        return 0 unless ($message);

        # create if not exists
        $self->touch_file($file);

        open( my $fh, '>>', $file ) || croak "Cannot Open $file!";
        print $fh "$message\n";
        close($fh) || croak "Cannot Close $file!";
    } else {
        return 0;
    }
};

sub pre_insert   { inner() }

sub touch_file {
    my ($self, $file) = @_;
    
    return if ( -e $file );
    
    open( my $fh, '>', $file ) || croak "Cannot Open $file!";
    print $fh "...\n";
    close($fh) || croak "Cannot Close $file!";
}

no Moose;

1;
__END__

=head1 NAME

IRC::Bot::Log::Extended - extends IRC::Bot::Log for IRC::Bot

=head1 SYNOPSIS

    #!/usr/bin/perl -w
    
    package IRC::Bot2;
    
    use Moose;
    extends 'IRC::Bot';
    use IRC::Bot::Log::Extended;
    
    after 'bot_start' => sub {
        my $self = shift;
    
        no warnings;
        $IRC::Bot::log =  IRC::Bot::Log::Extended->new(
            Path          => $self->{'LogPath'},
            split_channel => 1,
            split_day     => 1,
        );
    };
    
    package main;
    
    # Initialize new object
    my $bot = IRC::Bot2->new( # check IRC::Bot for more details
        Debug    => 0,
        Nick     => 'Fayland',
        Server   => 'irc.perl.org',
        Channels => [ '#moose', '#catalyst', '#dbix-class' ],
        LogPath  => '/home/fayland/irclog/',
    );
    
    # Daemonize process
    $bot->daemon();
    
    # Run the bot
    $bot->run();
    
    1;

=head1 DESCRIPTION

The SYNOPSIS above does two tasks.

=over 4

=item 1

it creates a custom IRC::Bot2 based on L<IRC::Bot>. The only differece is override $IRC::Bot::log with

    $IRC::Bot::log =  IRC::Bot::Log::Extended->new(
        Path          => $self->{'LogPath'},
        split_channel => 1,
        split_day     => 1,
    );

=item 2

the usage of IRC::Bot2 is the same as IRC::Bot. no difference. read L<IRC::Bot> for configuration and usage.

=back

=head1 ATTRIBUTES

L<IRC::Bot::Log> stores all channels all days into one file I<channel.log>. it is not so good to read. B<IRC::Bot::Log::Extended> splits the log into several files by channel AND|OR day.

=over 4

=item B<Path>

the place I<moose_20081009.log> stores.

=item B<split_channel>

default is 1. Instead store all log into channel.log, we split them into moose.log, catalyst.log and dbix-class.log

=item B<split_day>

default is 1. Instead store all log into channel.log or moose.log, we split them into channel_20081009.log, channel_20081010.log (moose_20081010.log) and etc. daily.

=back

=head1 AUGMENTABLE METHODS

The method B<pre_insert> can be augmented in a subclass to add extra functionality 
to your control script. here is two examples:

L<http://fayland.googlecode.com/svn/trunk/CPAN/IRC-Bot-Log-Extended/examples/02b_with_filter.pl>

L<http://fayland.googlecode.com/svn/trunk/CPAN/IRC-Bot-Log-Extended/examples/03advanced.pl>

  augment pre_insert => sub {
    my ($self, $file_ref, $message_ref) = @_;
    
    # change filename
    $$file_ref .= '.html';
    
    # HTML-lize
    $$message_ref =~ s/\</\&lt\;/isg;
    
    # find URIs
    my $finder = URI::Find->new(
        sub {
            my ( $uri, $orig_uri ) = @_;
            return qq|<a href="$uri">$orig_uri</a>|;
        }
    );
    $finder->find( $message_ref );
    
    $$message_ref .= "</br>";
  };

the example above is to make a HTML IRC log by youself.

=head1 SEE ALSO

L<IRC::Bot>, L<IRC::Bot::Log>, L<Moose>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

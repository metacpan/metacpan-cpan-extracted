package Log::Sigil;
use strict;
use warnings;
use Exporter "import";
use List::Util qw( max );

use constant DEBUG => 0;

our @EXPORT  = qw( swarn swarn2 );
our $VERSION = "1.02";

our @SIGILS    = (
    qw(
        =
        +
        !
        @
    ),
    q{#},
    qw(
        $
        %
        ^
        &
        *
        -
        |
        \
        ~
        ?
    ),
);
our $TIMES     = 3;
our $SEPARATOR = q{ };
our $BIAS      = 0;
our %INDEX     = ( "main::" => 0 ); # Ensure `values` + 1 is the next.
my $ANON_REGEX = qr{ (?: .*::__ANON__ | [(]eval[)] ) \z}msx;

sub swarn {
    my $nth  = 0;
    my $bias = 1;

    $nth++
        while caller $nth;

    my( $package, $filename, $line, $subroutine ) = caller $nth - $bias - $BIAS;

    $bias++;

    $subroutine = "main::"
        if $subroutine eq join q{::}, __PACKAGE__, "swarn";

    $subroutine = "${subroutine}::$line"
        if $subroutine =~ m{$ANON_REGEX};

    $bias++
        if $subroutine =~ m{$ANON_REGEX};

    if ( my @list = caller $nth - $bias - $BIAS ) {
        ( undef, undef, $line ) = @list;
    }

warn "\$package:\t$package"       if DEBUG;
warn "\$filename:\t$filename"     if DEBUG;
warn "\$line:\t$line"             if DEBUG;
warn "\$subroutine:\t$subroutine" if DEBUG;

    unless ( exists $INDEX{ $subroutine } ) {
        $INDEX{ $subroutine } = max( values %INDEX ) + 1;
    }

    my $sigil = $SIGILS[ $INDEX{ $subroutine } % @SIGILS ];
warn "\$sigil:\t$sigil" if DEBUG;
    unshift @_, $sigil x $TIMES, $SEPARATOR;
    push @_, " by ${filename}[$line]: $subroutine\n"; # Ignore if original has \n at the end.

    warn @_;
}

sub swarn2 {
    local $BIAS = $BIAS + 1;
    &swarn;
}

1;
__END__

=head1 NAME

Log::Sigil - show warnings with sigil prefix

=head1 SYNOPSIS

  filename: synopsis.pl
   1 use Log::Sigil qw( swarn swarn2 );
   2
   3 sub foo {
   4     swarn( "foo" );
   5     swarn( "bar" );
   6 }
   7
   8 swarn( "foo" );
   9
  10 foo( );
  11
  12 swarn( "bar" );

  above shows:
  === foo by synopsis.pl[8]: main::
  +++ foo by synopsis.pl[4]: main::foo
  +++ bar by synopsis.pl[5]: main::foo
  === bar by synopsis.pl[12]: main::

=head1 DESCRIPTION

This module helps printing debug by adding prefix to the warning message.
The prefix will change if caller changes, meaning 'foo' sub, and 'bar' sub
have different prefix each other.

i do printing debug frequently.  In debugging, my warning messages became
too big to read.  When i in trouble (yes, so doing printing
debug), i do not want to remove the warning messages.  Once i thought it is needed,
it is needed twice, and more.  Thus, i need a format which can read warning messages
even if that is big.

=head1 EXPORTS

=over

=item swarn

=item swarn2

=back

=head1 FUNCTIONS

=over

=item swarn

Works all of this module does.  That are,
adding prefix,
setting up filename and line,
and, setting up package and subroutine.

=item swarn2

Same as swarn, but has a 1 bias.  This is useful when calling from
some handler subroutine, such as;

  ( my $ua = LWP::UserAgent->new )->add_handler(
      request_prepare => sub {
          my( $req, $ua, $h ) = @_;
          swarn2( "Adding If-Modified-Since..." );
          $req->...
          swarn2( "Now req has: ", $req->header( "If-Modified-Since" ) );
      },
  );

swarn does not work well this case; this has deep frames.

Oops, that case needs more depth.  Increase BIAS value these cases.

  ( my $ua = LWP::UserAgent->new )->add_handler(
      request_prepare => sub {
          my( $req, $ua, $h ) = @_;
          local $Log::Sigil::BIAS += 4;
          swarn( "Adding" );
      },
  );
  $ua->get( "http://example.com/" );
  # --> +++ Adding by .../LWP/UserAgent.pm[243]: LWP::UserAgent::prepare_request

=back

=head1 PROPERTIES

=over

=item SIGILS

Is a array which are used as prefix.

=item TIMES

Specifies how many sigil is repeated.

=item SEPARATOR

Will be placed between sigils and log message.

=item BIAS

Controls caller frame depth.

=back

=head1 AUTHOR

kuniyoshi kouji E<lt>kuniyoshi@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


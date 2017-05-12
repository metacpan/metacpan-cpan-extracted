package Log::Log4perl::Filter::CallerMatch;
BEGIN {
  $Log::Log4perl::Filter::CallerMatch::VERSION = '1.200';
}

# ABSTRACT:  Filter Log4perl messages based on call frames

use 5.006;
use strict;
use Log::Log4perl::Config;
use base 'Log::Log4perl::Filter';
use Carp;


sub new {
    my ( $class, %options ) = @_;

    my $self = {
        AcceptOnMatch => 1,
        MinCallFrame  => 0,
        MaxCallFrame  => 5,
        %options,
    };

    $self->{AcceptOnMatch}  = Log::Log4perl::Config::boolean_to_perlish( $self->{AcceptOnMatch} );
    $self->{SubToMatch}     = defined $self->{SubToMatch} ? qr($self->{SubToMatch}) : qr/.*/;
    $self->{PackageToMatch} = defined $self->{PackageToMatch} ? qr($self->{PackageToMatch}) : qr/.*/;
    $self->{StringToMatch}  = defined $self->{StringToMatch} ? qr($self->{StringToMatch}) : qr/.*/;

    if ( defined $self->{CallFrame} ) {
        $self->{MinCallFrame} = $self->{MaxCallFrame} = $self->{CallFrame};
    }

    bless $self, $class;

    return $self;
}


sub ok {
    my ( $self, %p ) = @_;

    my $message = join $Log::Log4perl::JOIN_MSG_ARRAY_CHAR, @{ $p{message} };

    my ( $s_regex, $p_regex, $m_regex ) = ( $self->{SubToMatch}, $self->{PackageToMatch}, $self->{StringToMatch} );

    # First climb out of Log4perl's internals (differs depending on whether Boolean is being used etc..
    my $base = 0;
    $base++ while caller($base) =~ m/^Log::Log4perl/;

    foreach my $i ( $self->{MinCallFrame} .. $self->{MaxCallFrame} ) {
        my ( $package, $sub ) = ( caller $i + $base )[ 0, 3 ];
        next unless $package;
        next unless $sub;
        no warnings;
        if ( $sub =~ $s_regex && $package =~ $p_regex && $message =~ $m_regex ) {
            return $self->{AcceptOnMatch};
        }
    }
    return !$self->{AcceptOnMatch};
}

1;


=pod

=head1 NAME

Log::Log4perl::Filter::CallerMatch - Filter Log4perl messages based on call frames

=head1 VERSION

version 1.200

=head1 DESCRIPTION

This Log4perl custom filter checks the call stack using caller() and filters
the subroutine and package using user-provided regular expressions. You can specify
a specific call frame to test against, or have the filter iterate through a range of call frames.

=head1 ATTRIBUTES

=head2 StringToMatch

A perl5 regular expression, matched against the log message.

=head2 AcceptOnMatch

Defines if the filter is supposed to pass or block the message on a match (C<true> or C<false>).

=head2 PackageToMatch

A perl5 regular expression, matched against the 1st item in the array returned by caller() (e.g. "package")

=head2 SubToMatch

A perl5 regular expression, matched against the 4th item in the array returned by caller() (e.g. "subroutine")

=head2 CallFrame

The call frame to use when requesting information from caller(). (e.g. $i in caller($i)

=head2 MinCallFrame

The first call frame tested against when iterating through a series of call frames. Ignored if CallFrame specified.

=head2 MaxCallFrame

The last call frame tested against when iterating through a series of call frames. Ignored if CallFrame specified.

=head1 METHODS

=head2 new

Constructor. Refer to L<Log::Log4perl::Filter> for more information

=head2 ok

Decides whether log message should be accepted or not. Refer to L<Log::Log4perl::Filter> for more information

=head1 USAGE

 # log.conf
 log4perl.logger = ALL, A1
 log4perl.appender.A1        = Log::Log4perl::Appender::TestBuffer
 log4perl.appender.A1.Filter = MyFilter
 log4perl.appender.A1.layout = Log::Log4perl::Layout::SimpleLayout

 log4perl.filter.MyFilter                = Log::Log4perl::Filter::CallerMatch
 log4perl.filter.MyFilter.SubToMatch     = WebGUI::Session::ErrorHandler
 log4perl.filter.MyFilter.PackageToMatch = Flux::
 log4perl.filter.MyFilter.StringToMatch  = Operand1

=head1 SEE ALSO

L<Log::Log4perl::Filter>,
L<Log::Log4perl::Filter::StringMatch>,
L<Log::Log4perl::Filter::LevelMatch>,
L<Log::Log4perl::Filter::LevelRange>,
L<Log::Log4perl::Filter::Boolean>

=head1 AUTHOR

Patrick Donelan <pdonelan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Patrick Donelan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


1;

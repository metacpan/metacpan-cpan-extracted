package Log::Log4perl::DataDumper;

use warnings;
use strict;

our $VERSION = '0.01';

use Data::Dumper;

sub override
{
    my ($log, $multiline) = @_;

    my $oldcoderef = $log->{OFF};   # OFF is always "ON"

    my $overridesub = sub
    {
        my $logger = shift;
        my $level = pop;

        #
        # Reasonably nice options:
        # Should I allow user to change these?
        #
        local $Data::Dumper::Indent = 1;
        local $Data::Dumper::Quotekeys = 0;
        local $Data::Dumper::Terse = 1;
        local $Data::Dumper::Sortkeys = 1;

        #
        # Go ahead and handle CODE and filter before calling oldcoderef
        # so they are coverred by multiline
        #
        @_ = map { ref $_
                   ? (ref $_ eq 'CODE'
                      ? $_->()
                      : ((ref $_ eq 'HASH' and ref $_->{filter} eq 'CODE')
                         ? $_->{filter}->($_->{value})
                         : Dumper($_)))
                   : $_
                 } @_;

        if ($multiline)
        {
            foreach (@_)
            {
                foreach my $line (split(/\r?\n/))
                {
                    $oldcoderef->($logger, $line, $level);
                }
            }
        }
        else
        {
            $oldcoderef->($logger, @_, $level);
        }
    };

    foreach my $levelname (keys %Log::Log4perl::Level::PRIORITY)
    {
        if ($log->{$levelname} == $oldcoderef)
        {
            $log->{$levelname} = $overridesub;
        }
    }
}

1;

=head1 NAME

Log::Log4perl::DataDumper - Wrapper for Log4perl auto Data::Dumper objects

=head1 SYNOPSIS

 use Log::Log4perl qw(get_logger);
 use Log::Log4perl::DataDumper;

 my $logger = get_logger();

 Log::Log4perl::DataDumper::override($logger);

 $logger->debug('Some Object: ', ['an', 'array'],
                'Another: ', { a => 'b' });

=head1 DESCRIPTION

The Log4perl FAQ has the question "How can I drill down on references
before logging them?"

As discussed there, you don't want to say

 $logger->debug(Data::Dumper::Dumper($objref))

since the Dumper() will get called regardless of whether debugging is
on or not.

This can be handled optimally a couple ways with the stock Log4perl
mechanisms:

 $logger->debug(sub { Data::Dumper::Dumper($objref) });

or

 $logger->debug( {filter => \&Data::Dumper::Dumper,
                  value  => $objref} );

both of which are sort of ugly.

After calling C<Log::Log4perl::DataDumper::override($logger)>, you can
just say:

 $logger->debug($objref);

As a special added bonus, you can add an extra flag to the override line:

 Log::Log4perl::DataDumper::override($logger, 1)

and it will automatically handle multiline messages in the style of
L<Log::Log4perl::Layout::PatternLayout::Multiline>, but it will work
with any Layout defined instead of just PatternLayout since they are
handled "up front" so to speak.

=head1 SEE ALSO

 L<Log::Log4perl>
 L<Data::Dumper>

=head1 AUTHOR

Curt Tilmes, E<lt>ctilmes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Curt Tilmes

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

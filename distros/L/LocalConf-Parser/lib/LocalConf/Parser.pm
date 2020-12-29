package LocalConf::Parser;

use 5.006;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT = qw(conf_parser);

=head1 NAME

LocalConf::Parser - read config to an hashref from local conf files.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

    use config::parser;

    my $confref = conf_parser($config_file_loc);
    ...

=head1 EXPORT

conf_parser

=head1 METHOD

=head2 conf_parser

=cut

sub conf_parser {
    (my $config ) = @_;
    my %config_env;
    open CONFIG, "<", $config
        or die("Cannot read config file " . $config);
    while (<CONFIG>) {
        # skip blank lines
        next if /^\s*$/;
        # skip comments
        next if /^\s*#/;
        # parse line like 'key = "value"'
        /^\s*([\w_.-]+)\s*=\s*"([~\w,:\/;._\s\d!=-]*)"/;
        my ($key, $value) = ($1, $2);
        if (!$key && !$value || !defined($value)) {
            die "Can't parse config file " . $config . " line ${.}. Ignoring.";
            next;
        }
        # values with commas will be split and each item parsed
        if ($value =~ /,|=/) {
            for my $item (split /,/, $value) {
                # skip empty values
                next unless $item;
                if ( $item =~ /([\w_.\d\/:-]+)\s*=\s*([\w_.\d\/:-]*)/ ) {
                    # turn 'foo = "bar=jazz,blah=grub"' into
                    #  $config_env{foo} = { "bar" => "jazz", "blah" => "grub" }
                    $config_env{$key}{$1} = $2;
                } else {
                    # turn 'foo = "bar,blah,grub" into
                    #  $config_env{foo} = ( "bar", "blah", "grub" );
                    push @{$config_env{$key}}, $item;
                }
            }
        } else {
            # regular 'key = "value"' line
            $config_env{$key} = $value;
        }
    }
    # mark config file as read
    my $config_read = 1;
    close CONFIG or trap("Cannot close config file " . $config);
    # return reference to config data
    return \%config_env;
}

=head1 AUTHOR

nickniu, C<< <nick.niu.china at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-config-parser at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=config-parser>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc config::parser


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=config-parser>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/config-parser>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/config-parser>

=item * Search CPAN

L<https://metacpan.org/release/config-parser>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2020 nickniu.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of config::parser

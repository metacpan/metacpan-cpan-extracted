package Data::FormValidator::Filters::HTML::Acid;
use base qw(Exporter);
use warnings;
use strict;
use Carp;
use vars qw(@EXPORT);

@EXPORT = qw(filter_html);

use HTML::Acid;

use version; our $VERSION = qv('0.0.3');

# Module implementation here

sub filter_html {
    my %args = @_;
    return sub {
        my $text = shift;
        my $parser = HTML::Acid->new(%args);
        return $parser->burn($text);
    };
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Data::FormValidator::Filters::HTML::Acid - HTML::Acid in a popular data cleansing framework

=head1 VERSION

This document describes Data::FormValidator::Filters::HTML::Acid version 0.0.3

=head1 SYNOPSIS

    use Data::FormValidator;
    use Data::FormValidator::Filters::HTML::Acid;
    my %profile = (
        field_filters = {
            html => filter_html(),
        },
        required =>  ['html'],
    );
    my $results = Data::FormValidator->check($cgi, \%profile);
  
=head1 DESCRIPTION

This is a simple wrapper that makes L<HTML::Acid> available as a 
filter in the L<Data::FormValidator> framework.

=head1 INTERFACE 

=head2 filter_html

This method takes the L<HTML::Acid> constructor arguments and returns
a filter object that wraps the L<HTML::Acid> object.

=head1 DEPENDENCIES

This module is intended to be used in the L<Data::FormValidator> framework.

=head1 AUTHOR

Nicholas Bamber  C<< <nicholas@periapt.co.uk> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Nicholas Bamber C<< <nicholas@periapt.co.uk> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

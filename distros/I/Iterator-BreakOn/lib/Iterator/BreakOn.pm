package Iterator::BreakOn;
use base qw(Iterator::BreakOn::Base);
use warnings;
use strict;
use Carp;
use utf8;
use English;

our $VERSION = '0.2';

# Module implementation here
sub new {
    my  $class  =   shift;
    my  @params =   @_;

    return $class->SUPER::new( 'getmethod' => 'get_column', @params );
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Iterator::BreakOn - Iterator with control flow breaks

=head1 SYNOPSIS

    use Iterator::BreakOn;

    #
    #   get a generic data source with a next method implemented whom
    #   returns a generic object 
    #
    #   in this example the order of the items in the data stream is assumed
    #   to be:
    #       location, zipcode, name
    #
    my $datasource = $myschema->resultset('mytable')->search();

    my $iter = Iterator::BreakOn->new( 
                    datasource => $datasource,
                    break_before => [ 
                            qw(location) 
                            ],
                    break_after => [ 
                            'location'  =>  \&after_location,
                            'zipcode' 
                            ],
                    on_last_item    =>  sub { print "Finnished !"; },
                    );

    #                    
    # There are three uses modes:
    #
    #   Fully automatic mode: useless if not defined code for breaks
    $iter->run();

    #   Semi-automatic mode: get only the item (run automatically the other
    #   events)
    while (my $data_item = $iter->next()) {
        # do something with data ...
        1;
    }

    #   Manual mode: get every event as an object
    while (my $event = $iter->next_event()) {
        if ($event->name() eq 'before_location') {
            # do something before a new location comes
            
        }
        elsif ($event->name() eq 'after_zipcode')) {
            # do something after the last zipcode reached
            
        }
        elsif ($event->name() eq 'next_item' ) {
            # get the item (including the first and last items)
            my $data = $iter->next();

            # and do something whit him

        }
        elsif ($event->name() eq 'last_item') {
            # and do something when the end of data reached

        }
    } # end while

=head1 DESCRIPTION

=head2 Events order

Whatever the run mode this is the order of the events:

=over

=item * on_first

Event raise before the first item.

=item * before_XXXX

Multiple event raise before the XXXX field change his value in the next item.

=item * on_every

Raise for each item.

=item * after_XXXX

Multiple event raise after the XXXX field change his value in the next item.
The order is deep first.

=item * on_last

Raise after the last item.

=back

=head1 INTERFACE 

This module inherits from L<Iterator::BreakOn::Base>. See this module for
detailed documentation about methods.

=head1 DIAGNOSTICS

The package uses the L<Exception::Class> library for error management. See
L<Iterator::BreakOn::X> for the list of exceptions.

=head1 CONFIGURATION AND ENVIRONMENT

Iterator::BreakOn requires no configuration files or environment variables.

=head1 DEPENDENCIES

The module needs the following Perl modules:

=over

=item L<Class::Accessor>

=item L<Exception::Class>

=item L<Test::More>

=item L<Text::CSV>

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to the author.

=head1 AUTHOR

Víctor Moral <victor@taquiones.net>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007 <Victor Moral>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License or
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

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

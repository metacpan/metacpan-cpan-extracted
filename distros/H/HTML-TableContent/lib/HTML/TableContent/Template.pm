package HTML::TableContent::Template;

use strict;
use warnings;
use Carp qw/croak/;
use MooX::ReturnModifiers;
use HTML::TableContent::Table;
use HTML::TableContent::Table::Caption;
use HTML::TableContent::Table::Header;

our $VERSION = '0.18';

my %TABLE = (
    caption => 'HTML::TableContent::Table::Caption',
    header => 'HTML::TableContent::Table::Header',
    row => 'HTML::TableContent::Table::Row',
    cell => 'HTML::TableContent::Table::Row::Cell',
);

sub import {
    my ( $self, @import ) = @_;
    
    my $target = caller;
    
    my %modifiers = return_modifiers($target);

    my @target_isa;

    return if $target->can('_table');

    { no strict 'refs'; @target_isa = @{"${target}::ISA"} };

    if (@target_isa) {   
        eval '{
        package ' . $target . ';

            sub _caption_spec {
                my ($class, @meta) = @_;
                return $class->maybe::next::method(@meta);
            }

            sub _header_spec {
                my ($class, @meta) = @_;
                return $class->maybe::next::method(@meta);
            }
            
            sub _row_spec {
                my ($class, @meta) = @_;
                return $class->maybe::next::method(@meta);
            }
            
            sub _cell_spec {
                my ($class, @meta) = @_;
                return $class->maybe::next::method(@meta);
            }
            
        1;
        }';
    }

    $modifiers{has}->( 'package' => ( is => 'ro', lazy => 1, default => sub { return $target; } ) );

    my $apply_modifiers = sub {
       $modifiers{with}->('HTML::TableContent::Template::Base');
    };

    for my $element (keys %TABLE) {
        my @element = ();
        my $option = sub {
            my ( $name, %attributes ) = @_;
            
            my $element_data = { };
            my %filtered_attributes = _filter_attributes($name, $element, %attributes);

            if ( $element =~ m{caption|header}ixms ){ 
                $modifiers{has}->( $name => %filtered_attributes );
            }

            delete $filtered_attributes{default};

            $element_data->{$name} = \%filtered_attributes;
           
            my $spec = sprintf('_%s_spec', $element);
            if ( $element =~ m{row|cell}ixms ) {
                $modifiers{around}->(
                    $spec => sub {
                        my ( $orig, $self ) = ( shift, shift );
                        return $self->$orig(@_), %$element_data;
                    }
                );
            } else {
                push @element, $element_data;
                $modifiers{around}->(
                    $spec => sub {
                        my ( $orig, $self ) = ( shift, shift );
                        return $self->$orig(@_), \@element;
                    }
                );
            }
            return;
        };

        { no strict 'refs'; *{"${target}::$element"} = $option; }
    }

    $apply_modifiers->();

    return; 
}

sub _filter_attributes {
    my ($name, $element,  %attributes) = @_;

    $attributes{template_attr} = $name;

    if ( ! exists $attributes{text} ) {
        $attributes{text} = $name;
    }

    if ( $element eq 'cell' && exists $attributes{alternate_classes} ) {
         my @classes = @{ $attributes{alternate_classes} };
         $attributes{oac} = \@classes;
    }

    my %tattr = %attributes;
    $attributes{is} = 'ro';
    $attributes{lazy} = 1;
    if ( $element =~ m{row|cell}ixms ) {
        $attributes{default} = sub { return \%tattr; };
    } else {
        my $class = $TABLE{$element};
        $attributes{default} = sub { my %aah = %tattr; return $class->new(\%aah); };
    }

    return %attributes;
}

1;

__END__

=head1 Name

HTML::TableContent::Template - MooX Template Tables.

=head1 VERSION

Version 0.18

=cut

=head1 SYNOPSIS

    package MyApp::Table::Demo;

    use Moo;
    use HTML::TableContent::Template;
    
    header id => ( 
        class => 'table-header',
        id => 'header-id',
        cells => {
            class => 'id-col',
        }
    );

    header name => (
        class => 'table-name',
        id => 'header-name'
        cells => {
            class => 'name-col',
        }
    );

    row all => (
        class => 'table-rows'
    );

    .... 

    my $template = MyApp::Table::Demo->new({ data => $aoh });
    $template->render;
    
    ...

    my $name_header_class = $template->name->class              # header-id
    my $first_id_cell = $template->id->get_first_cell->class    # id-col
    my $table = $template->table;  
        
=head1 DESCRIPTION

Define Table Template Classes - For options see L<HTML::TableContent::Template::Base>

=head1 SUBROUNTINES/METHODS

=head2 Attributes

=head3 header

header's define your table. name should be a reference to a key/header in your passed data - L<HTML::TableContent::Table::Header>'r.

    header name => (
        ...
    );

    ...

    header id => (
        ...
        cells => {
            ....
        }
    );

=head3 caption

Optional - L<HTML::TableContent::Table::Caption>. 

    caption title => (
        ....
    );

=head1

=head2 HashRefs

=head2 row

Rows are merged into a hashref that is used to generate the table, at ->new({ }). After that point _row_spec is far more useful.

    row all => (
        ...
    );
    
    ...

    row one => (
        ...
        cells => {

        }
    );

=head2 cell

Cells are also merged into a hashref that is used when generating the table, at ->new({ }). After that point _cell_spec is far more useful.

    cell odd => (
        ...
    );

=head2 Naming Rows and Cells

Both Rows and Cells follow the same naming convention.

    row all => ( class => 'text' )  # applies class - 'text - to all rows/cells
    cell odd => ( class => 'text' ) # applies class - 'text' - to all odd rows/cells 
    row even => ( class => 'text' ) # applies class - 'text' - to all even rows/cells
    row one => ( class => 'text' ) # applies class - 'text' - to only the first row
    cell one__one => ( class => 'text' ) # applies class - 'text' - to only the first cell in the first row
    row magical => ( index => 1, ) # finally you can also set an index if you want to feel special

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS AND LIMITATIONS

=head1 ACKNOWLEDGEMENTS

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT 

=head1 INCOMPATIBILITIES

=head1 LICENSE AND COPYRIGHT

Copyright 2016 LNATION.

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



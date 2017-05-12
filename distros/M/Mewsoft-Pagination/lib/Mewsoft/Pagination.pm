#=Copyright Infomation
#==========================================================
#Module Name      : Mewsoft::Pagination
#Program Author   : Dr. Ahmed Amin Elsheshtawy, Ph.D. Physics
#Home Page          : http://www.mewsoft.com
#Contact Email      : support@mewsoft.com
#Products               : Auction, Classifieds, Directory, PPC, Forums, Snapshotter
#Copyrights © 2008 Mewsoft Corp. All rights reserved.
#==========================================================
#==========================================================
package Mewsoft::Pagination;

# pagination - pag·i·na·tion
#1. the process of numbering the pages of a book.
#2. the number and arrangement of pages, as might be noted in a bookseller’s catalogue.

$VERSION = '0.40';

use strict;

=head1 NAME

Mewsoft::Pagination - Standalone Object-Oriented Efficient Data Pagination

=head1 SYNOPSIS

	use Mewsoft::Pagination;
	
	#Example data
	my $total_entries = 100;
	my $entries_per_page = 10;
	my $pages_per_set = 7;
	my $current_page = 4;

	my $paginate = Mewsoft::Pagination->new(
		total_entries       => $total_entries, 
		entries_per_page    => $entries_per_page, 
		current_page        => $current_page,
		pages_per_set       => $pages_per_set,
		mode => "slide", #modes are 'slide', 'fixed', default is 'slide'
	);

	# General page information
	print "         First page: ", $paginate->first_page, "\n";
	print "          Last page: ", $paginate->last_page, "\n";
	print "          Next page: ", $paginate->next_page, "\n";
	print "      Previous page: ", $paginate->previous_page, "\n";
	print "       Current page: ", $paginate->current_page, "\n";

	# Entries on current page
	print "First entry on current page: ", $paginate->first, "\n";
	print " Last entry on current page: ", $paginate->last, "\n";

	#Returns the number of entries on the current page
	print "Entries on the current page: ", $paginate->entries_on_current_page, " \n";

	# Page set information
	print "First page of previous page set: ",  $paginate->previous_set, "\n";
	print "    First page of next page set: ",  $paginate->next_set, "\n";
  
	# Print the page numbers of the current set (visible pages)
	foreach my $page (@{$paginate->pages_in_set()}) {
		if($page == $paginate->current_page()) {
			print "<b>$page</b> ";
		} else {
			print "$page ";
		}
	}
	
	#This will print out these results:
	#First page: 1
	#Last page: 10
	#Next page: 5
	#Previous page: 3
	#Current page: 4
	#First entry on current page: 31
	#Last entry on current page: 40
	#Entries on the current page: 10 
	#First page of previous page set: 
	#First page of next page set: 11
	#     1 2 3 <b>4</b> 5 6 7 


=head1 DESCRIPTION

The standalone object-orinated module produced by Mewsoft::Pagination which 
does not depend on any other modules can be used to create page
navigation for any type of applications specially good for web applications. For example
I use it in our Forums software, Auctions, Classifieds, and also our Directory
Software andmany others. It makes live easier better than repeating the same code in your applications.

In addition it also provides methods for dealing with set of pages,
so that if there are too many pages you can easily break them
into chunks for the user to browse through. This part taken direct
from the similar module B<Data::Pageset>. Basically this module
is a duplicate of the module B<Data::Pageset>. The reason I created
this module is that all other pagination modules depends on other
modules which is also dependes on others modules. So it is not good
if you are building a large web application to ask your customers to
install such a small module to support your product.

This module is very friendly where you can change any single
input parameter at anytime and it will automatically recalculate
all internal methods data without the need to recreate the object again.

All the main object input options can be set direct and the module
will redo the calculations including the mode method.

You can include this module with your applications by extracting the
module package and copying the module file Pagination.pm to your
application folder and just replace this line in the above code:

B<use Mewsoft::Pagination;>

by this line:

B<use Pagination;>

You can even choose to view page numbers in your set in a 'sliding' fassion.

=head1 METHODS

=head2 new()

	use Mewsoft::Pagination;
	my $paginate = Mewsoft::Pagination->new(
		total_entries       => $total_entries, 
		entries_per_page    => $entries_per_page, 
		current_page        => $current_page,
		pages_per_set       => $pages_per_set,
		mode => "slide", #modes are 'slide', 'fixed', default is 'slide'
	);

This is the constructor of the object.

SETTINGS are passed in a hash like fashion, using key and value pairs. Possible settings are:

B<total_entries> - how many data units you have,

B<entries_per_page> - the number of entries per page to display,

B<current_page> -  the current page number (defaults to page 1) and,

B<pages_per_set> -  how many pages to display, defaults to 10,

B<mode> - the mode (which defaults to 'slide') determins how the paging will work.

=back 4

=cut

#==========================================================
#==========================================================
sub new {
my ($class, %args) = @_;
    
	my $self = bless {}, $class;
	
	#while (my($key, $value)=each(%args)) {print ("$key =  $value\n");}

	$args{total_entries} += 0;
	$args{entries_per_page} += 0;
	$args{current_page} += 0;
	$args{pages_per_set} += 0;
	
	$args{entries_per_page} = int($args{entries_per_page});
	$args{current_page} = int($args{current_page});
	$args{pages_per_set} = int($args{pages_per_set});

	$self->{total_entries} =  int($args{total_entries});
	$self->{entries_per_page} = $args{entries_per_page} > 0 ? $args{entries_per_page} : 10;
	$self->{current_page} = $args{current_page} > 0 ? $args{current_page} : 1;
	$self->{pages_per_set} = $args{pages_per_set} > 0 ? $args{pages_per_set} : 5;

    if ( defined $args{mode} && $args{mode} eq 'fixed' ) {
        $self->{mode} = 'fixed';
    } else {
        $self->{mode} = 'slide';
    }
	
	$self->_do_calculation();

    return $self;
}
#==========================================================
sub _do_calculation {
my ($self) = shift;
	
	# Calculate the total pages & the last page number
	$self->{last_page} = int ($self->{total_entries} / $self->{entries_per_page});
	if (($self->{total_entries} % $self->{entries_per_page})) { $self->{last_page}++; }
	$self->{last_page} = 1 if ($self->{last_page} < 1);
	$self->{total_pages} = $self->{last_page};

	if ($self->{current_page} > $self->{last_page}) {$self->{current_page} = $self->{last_page};}

	$self->{first_page} = 1;  #always = 1

	# calculate the first data entry on the current page
	if ($self->{total_entries} == 0) {
		$self->{first} = 0;
	} else {
		$self->{first} = (($self->{current_page} - 1) * $self->{entries_per_page}) + 1;
	}
	
	# calculate the last data entry on the current page
	if ($self->{current_page} == $self->{last_page}) {
		$self->{last} = $self->{total_entries};
	} else {
		$self->{last} = ($self->{current_page} * $self->{entries_per_page});
	}

	# Calculate entries on the current page
	if ($self->{total_entries} == 0) {
		$self->{entries_on_current_page} = 0;
	} else {
		$self->{entries_on_current_page} = $self->last - $self->first + 1;
	}
	
	#calculate the previous page number if any
	if ($self->{current_page} > 1) {
		$self->{previous_page} = $self->{current_page} - 1;
	} else {
		$self->{previous_page} = undef;
	}
	
	#calculate the next page number if any
	$self->{next_page} = $self->{current_page} < $self->{last_page} ? $self->{current_page} + 1 : undef;
	
	#calculate pages sets
	$self->_calculate_visible_pages();
	
	#check if the first page is currently in the pages set displayed
	$self->{first_page_in_set} = @{$self->{Page_Set_Pages}}[0] == 1 ? 1 : 0;
	#check if the last page is currently in the pages set displayed
	$self->{last_page_in_set} = @{$self->{Page_Set_Pages}}[$#{$self->{Page_Set_Pages}}] == $self->{last_page} ? 1 : 0;
}
#==========================================================

=head2 total_entries()

  $paginate->total_entries($total_entries);

This method sets or returns the total_entries. If called without 
any arguments it returns the current total entries.

=cut

sub total_entries {
my ($self) = shift; 
	if (@_) {
		$self->{total_entries} = shift ;
		$self->_do_calculation();
	}
	return $self->{total_entries};
}
#==========================================================

=head2 entries_per_page()

  $paginate->entries_per_page($entries_per_page);

This method sets or returns the entries per page (page size). If called without 
any arguments it returns the current data entries per page.

=cut

sub entries_per_page {
my ($self) = shift; 
	if (@_) {
		$self->{entries_per_page} = shift ;
		$self->_do_calculation();
	}
	return $self->{entries_per_page};
}
#==========================================================

=head2 current_page()

  $paginate->current_page($page_num);

This method sets or returns the current page. If called without 
any arguments it returns the current page number.

=cut

sub current_page {
my ($self) = shift; 
	if (@_) {
		$self->{current_page} = shift ;
		$self->_do_calculation();
	}
	return $self->{current_page};
}
#==========================================================

=head2 mode()
	
	$paginate->mode('slide');

This method sets or returns the pages set mode which takes only
two values 'fixed' or 'slide'. The default is 'slide'. The fixed mode will be
good if you want to display all the navigation pages.

=cut  

sub mode {
my ($self) = shift; 
	if (@_) {
		$self->{mode} = shift ;
		$self->_do_calculation();
	}
	return $self->{mode};
}
#==========================================================

=head2 pages_per_set()

  $paginate->pages_per_set($number_of_pages_per_set);

Sets or returns the number of pages per set (visible pages).
If called without any arguments it will return the current
number of pages per set.

=cut

sub pages_per_set {
my ($self) = shift; 
	if (@_) {
		$self->{pages_per_set} = shift ;
		$self->_do_calculation();
	}
	return $self->{pages_per_set};
}
#==========================================================

=head2 entries_on_current_page()

  $paginate->entries_on_current_page();

This method returns the number of entries on the current page.

=cut

sub entries_on_current_page {
my ($self) = shift;

	if ($self->{total_entries} == 0) {
		return 0;
	} else {
		return $self->last - $self->first + 1;
	}
}
#==========================================================

=head2 first_page()

  $paginate->first_page();

Returns first page. Always returns 1.

=cut

sub first_page {
my ($self) = shift;
	return 1;
}
#==========================================================

=head2 last_page()

  $paginate->last_page();

Returns the last page number, the total number of pages.

=cut

sub last_page {
my ($self) = shift; 
	return $self->{last_page};
}
#==========================================================

=head2 total_pages()

  $paginate->total_pages();

Returns the last page number, the total number of pages.

=cut

sub total_pages {
my ($self) = shift; 
	return $self->{last_page};
}
#==========================================================

=head2 first()

  $paginate->first();

Returns the number of the first entry on the current page.

=cut

sub first {
my ($self) = shift;
	return $self->{first};
}
#==========================================================

=head2 last()

  $paginate->last();

Returns the number of the last entry on the current page.

=cut

sub last {
my ($self) = shift;
	return $self->{last};
}
#==========================================================

=head2 previous_page()

  $paginate->previous_page();

Returns the previous page number, if one exists. Otherwise it returns undefined.

=cut

sub previous_page {
my ($self) = shift;
	return $self->{previous_page};
}
#==========================================================

=head2 next_page()

  $paginate->next_page();

Returns  the next page number, if one exists. Otherwise it returns undefined.

=cut

sub next_page {
my ($self) = shift;
	return $self->{next_page};
}
#==========================================================

=head2 first_page_in_set()

  $paginate->first_page_in_set();

Returns 1 if the first page is in the current pages set. Otherwise it returns 0.

=cut

sub first_page_in_set {
my ($self) = shift;
	return $self->{first_page_in_set};
}
#==========================================================

=head2 last_page_in_set()

  $paginate->last_page_in_set();

Returns 1 if the last page is in the current pages set. Otherwise it returns 0.

=cut

sub last_page_in_set {
my ($self) = shift;
	return $self->{last_page_in_set};
}
#==========================================================
#==========================================================
#==========================================================
# The code below originally from the module Data::Pageset
sub _calculate_visible_pages {
my ($self)= shift;

    unless ( $self->{pages_per_set} > 1 ) {
        # Only have one page in the set, must be page 1
        $self->{Page_Set_Previous} = $self->{current_page} - 1 if ($self->{current_page} != 1);
        $self->{Page_Set_Pages} = [1];
        $self->{Page_Set_Next}  = $self->{current_page} + 1 if ($self->{current_page} < $self->{last_page});
    } else {
        if ( $self->{mode} eq 'fixed' ) {
            my $starting_page = $self->_calc_start_page($self->{pages_per_set});
            my $end_page      = $starting_page + $self->{pages_per_set} - 1;

            if ( $end_page < $self->{last_page}) {
                $self->{Page_Set_Next} = $end_page + 1;
            }

            if ( $starting_page > 1 ) {
                $self->{Page_Set_Previous} = $starting_page - $self->{pages_per_set};
				$self->{Page_Set_Previous} =  1 if $self->{Page_Set_Previous} < 1;
            }

            $end_page = $self->{last_page} if ($self->{last_page} < $end_page);
            $self->{Page_Set_Pages} = [ $starting_page .. $end_page ];
        } else {

            # We're in slide mode

            # See if we have enough pages to slide
            if ( $self->{pages_per_set} >= $self->{last_page} ) {

                # No sliding, no next/prev pageset
                $self->{Page_Set_Pages} = [ '1' .. $self->{last_page} ];
            } else {

				# Find the middle rounding down - we want more pages after, than before
                my $middle = int( $self->{pages_per_set} / 2 );

                # offset for extra value right of center on even numbered sets
                my $offset = 1;
                if ( $self->{pages_per_set} % 2 != 0 ) {
                    # must have been an odd number, add one
                    $middle++;
                    $offset = 0;
                }

                my $starting_page = $self->{current_page} - $middle + 1;
                $starting_page = 1 if $starting_page < 1;
                my $end_page = $starting_page + $self->{pages_per_set} - 1;
                $end_page = $self->{last_page} if ($self->last_page() < $end_page);

                if ( $self->{current_page} <= $middle ) {
                    # near the start of the page numbers
                    $self->{Page_Set_Next} = $self->{pages_per_set} + $middle - $offset;
                    $self->{Page_Set_Pages} = [ '1' .. $self->{pages_per_set} ];
                } elsif ( $self->{current_page} > ( $self->{last_page} - $middle - $offset ) )
                {
                    # near the end of the page numbers
                    $self->{Page_Set_Previous} = $self->{last_page} - $self->{pages_per_set} - $middle + 1;
                    $self->{Page_Set_Pages}= [ ( $self->{last_page} - $self->{pages_per_set} + 1 ) .. $self->{last_page} ];
                } else {
                    # Start scrolling
                    $self->{Page_Set_Pages} = [ $starting_page .. $end_page ];
                    $self->{Page_Set_Previous} = $starting_page - $middle - $offset;
                    $self->{Page_Set_Previous} = 1 if $self->{Page_Set_Previous} < 1;
                    $self->{Page_Set_Next} = $end_page + $middle;
                }
            }
        }
    }

}
#==========================================================
# The code below originally from the module Data::Pageset
# Calculate the first page in the current set
sub _calc_start_page {
my ( $self) = @_;

    my $current_page_set = 0;

    if ( $self->{pages_per_set} > 0 ) {
        $current_page_set = int( $self->{current_page} / $self->{pages_per_set} );
        if ( $self->{current_page} % $self->{pages_per_set} == 0 ) {
            $current_page_set = $current_page_set - 1;
        }
    }

    return ( $current_page_set * $self->{pages_per_set} ) + 1;
}
#==========================================================

=head2 previous_set()

  print "Previous set starts at ", $paginate->previous_set(), "\n";

This method returns the page number at the start of the previous page set.
undef is return if pages_per_set has not been set.

=cut  

sub previous_set {
    my $self = shift;
    return $self->{Page_Set_Previous} if defined $self->{Page_Set_Previous};
    return undef;
}
#==========================================================

=head2 next_set()

  print "Next set starts at ", $paginate->next_set(), "\n";

This method returns the page number at the start of the next page set.
undef is return if pages_per_set has not been set.

=cut  

sub next_set {
my ($self) = shift;
    return $self->{Page_Set_Next} if defined $self->{Page_Set_Next};
    return undef;
}
#==========================================================

=head2 pages_in_set()

  foreach my $page_num (@{$paginate->pages_in_set()}) {
    print "Page: $page_num \n";
  }

This method returns an array ref of the the page numbers within
the current set. undef is return if pages_per_set has not been set.

=cut  

sub pages_in_set {
my ($self) = shift;
    return $self->{Page_Set_Pages};
}
#==========================================================
#==========================================================

=head1 EXPORT

None by default.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  <support@mewsoft.com>
Website: L<http://www.mewsoft.com>

=head1 SEE ALSO

L<Data::Page|Data::Page>.
L<Data::Pageset|Data::Pageset>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Ahmed Amin Elsheshtawy <support@mewsoft.com>,
L<http://www.mewsoft.com>

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

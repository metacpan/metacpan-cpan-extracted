package File::Attributes::Recursive;

use warnings;
use strict;

our $VERSION = '0.02';
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(get_attribute_recursively  get_attributes_recursively
		    list_attributes_recursively);

our %EXPORT_TAGS = (all => \@EXPORT_OK);

use File::Attributes qw(get_attribute list_attributes);
use Path::Class;
use Cwd qw(abs_path);
use Carp;

sub get_attribute_recursively {
    my $file      = shift;
    my $top       = shift;
    my $attribute = shift;
    
    if(!defined $attribute){
	$attribute = $top;
	$top = '/';
    }
    
    $file = file($file)->absolute;
    $top  = dir($top)->absolute;

    if(!$top->subsumes($file)){
	croak "get_attribute_recursively: filename ($file) must ".
	  "contain top ($top)";
    }
    
    my $result;
    while($top->subsumes($file)){
	eval {
	    $result = get_attribute($file, $attribute);
	};
	
	last if defined $result;
	
	$file = $file->parent;
    }
    
    return $result;
}

sub get_attributes_recursively {
    my $file = shift;
    my $top  = shift;

    $top = '/' if !defined $top;
    
    $file = file($file)->absolute;
    $top  = dir($top)->absolute;

    if(!$top->subsumes($file)){
	croak "get_attributes_recursively: filename ($file) must ".
	  "contain top ($top)";
    }
    
    my %result;
    while($top->subsumes($file)){
	my @attributes = list_attributes($file);
	
	foreach my $attribute (@attributes){
	    next if exists $result{$attribute};
	    eval {
		$result{$attribute} = get_attribute($file, $attribute);
	    };
	}
	
	$file = $file->parent;
    }
    
    return %result;
}

sub list_attributes_recursively {
    my $file = shift;
    my $top  = shift;

    $top = '/' if !defined $top;
    
    $file = file($file)->absolute;
    $top  = dir($top)->absolute;
    
    if(!$top->subsumes($file)){
	croak "get_attributes_recursively: filename ($file) must ".
	  "contain top ($top)";
    }
    
    my %results;
    while($top->subsumes($file)){
	eval {
	    my @subresults = list_attributes($file);
	    @results{@subresults} = @subresults;
	};
	$file = $file->parent;
    }
    
    return keys %results;
}

__END__

=head1 NAME

File::Attributes::Recursive - Inherit file attributes from parent
directories.

=head1 VERSION

Version 0.02


=head1 SYNOPSIS

Works like C<File::Attributes>, but will recurse up the directory tree
until a matching attribute is found.

=head1 EXPORT

None, by default.  Specify the functions you'd like to use as
arguments to the module.  C<:all> means export everything.

=head1 FUNCTIONS

=head2 get_attribute_recursively($file, [$top], $attribute)

Returns the value of attribute C<$attribute>.  If C<$top> is
specified, then the search will terminate when the path no longer
contains C<$top>.  (i.e. if C<$file> is C</foo/bar/baz/quux> and C<$top> is 

=head2 get_attributes_recursively($file, [$top])

Returns a hash of key value pairs for all attributes that apply to
C<$file>.  Only the closest attributes are returned.  Given:

      /a            (a = yes, foo = bar)
      /a/b          (b = yes, foo = baz)
      /a/b/c        (c = yes)

C<get_attributes_recursively('/a/b/c', '/a')> will return:

     (a => yes, b => yes, c => yes, foo => baz).

The C<< foo => bar >> is masked by the "closer" C<< foo => baz >>.

=head2 list_attributes_recursively($file, [$top])

Returns a list of attributes that are defined and apply to C<$file>.
Like C<keys get_attributes_recursively($file, [$top])>, but faster.

=head1 NOTABLY ABSENT FUNCTIONS

=head2 unset_attribute_recursively

There are two possible ways for this function to behave -- either
recurse until the attribute is removed, or recurse to C<top>, removing
the attribute at each level.  The first doesn't make sense, and the
second is dangerous.  If you need this function, write it for the
specific needs of your application; I think that's the safest thing to
do.

(Note that C<rm> refuses to C<rm ..>, so I think there's some
precedent here.)

=head1 AUTHOR

Jonathan Rockway, C<< <jrockway at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-file-attributes-recursive at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Attributes-Recursive>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Attributes::Recursive

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Attributes-Recursive>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Attributes-Recursive>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Attributes-Recursive>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Attributes-Recursive>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Jonathan Rockway, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of File::Attributes::Recursive

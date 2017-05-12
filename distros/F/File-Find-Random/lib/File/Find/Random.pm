
package File::Find::Random;
use File::Find qw();
use strict;
use File::Spec::Functions;
use Error;
use warnings;
our $VERSION = '0.5';
package Error::File::Find::Random;
our @ISA = qw(Error);
$VERSION = 1;
package File::Find::Random;

=head1 NAME

File::Find::Random - 

=head1 SYNOPSIS

  use File::Find::Random;

  
  my $file = File::Find::Random->find();

  my $file = File::Find::Random->find('path/');

  my $finder = File::Find::Random->new();
  $finder->base_path('/foo/bar');
  my $file = $finder->find();

=head1 DESCRIPTION

Randomly selects a file from a filesystem.

=head1 METHODS

=head2 new

Returns a find object.

=head2 base_path

Sets or returns the base_path

=head2 find

The biggest function, can be called as a class method or a object method. 
Automagically will set base_path if passed a parameter. Returns a random file.

If it cannot find a file it will throw an exception of type Error::File::Find::Random.

=cut


my $file;
my $error;
sub new {
    my $scalar = undef;
    return bless \$scalar, shift;
}

sub find {
    my $self = shift;
    $self = $self->new() unless(ref($self));
    if(@_) {
	$self->base_path(shift());
    }
    $file = undef;
    $error = undef;
    File::Find::find(
	 {
	     wanted => \&find_wanted_cb,
	     preprocess => \&find_filter_cb,
	     no_chdir => 1,
	 },
	 $self->base_path || curdir()
	 );
    my $found_file = $file;
    $file = undef;
    if(-d $found_file) {
        die with Error::File::Find::Random -text => "Cannot find a file in this pass at '$error'\n";
    }
    return $found_file;
}

sub find_filter_cb {
    my @dirs = grep { $_ ne curdir() && $_ ne updir() } @_;
    if(@dirs) {
      return $dirs[rand(@dirs)]
    } 
    $error = $File::Find::dir;
    return;
}

sub find_wanted_cb {
    $file = $_;
}

sub base_path {
    my $self = shift;
    if(@_) {
	$$self = shift;
	return $self;
    }
    return $$self;
}

=head1 BUGS

If the finder finds a empty directory or a finds itself in a place where it has no permissions to descend further, it will throw an error. This might be seen as a bug and might get fixed.

While it is random which file is selected, there is no mechanism in place to counter the imbalance that occurs if you have varying depth of directories. However our use is on very big filesystem with equally distributed directory structures.

=head1 AUTHOR

    Arthur Bergman
    arthur@fotango.com
    http://opensource.fotango.com/

=head1 COPYRIGHT

Copyright 2003 Fotango Ltd All Rights Reserved.

This module is released under the same license as Perl itself.

=cut


1; #this line is important and will help the module return a true value
__END__


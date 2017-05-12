package File::Box;

use 5.006; use strict; use warnings;

our $VERSION = '0.01';

use FindBin;

use File::Basename qw(dirname);

use Path::Class;

use Class::Maker qw(:all);

Class::Maker::class
{
    public =>
    {
        string => [qw( mother_file boxdir )],

	hash => [qw( env )],
    },
};

sub _preinit : method
{
    my $this = shift;


    $this->boxdir( '.box' );
    
    $this->mother_file( __FILE__ );
}

sub _postinit : method
{
    my $this = shift;

    $this->env( { $this->env, 

		       HOME => $this->path_home,

		       LOCAL => $this->path_local,		       
		   }
		   );
}

sub path_home : method
{
    my $this = shift;


    my $this_file = $this->mother_file;

    $this_file =~ s/\.pm$//gi;

    my $dir = Path::Class::Dir->new( $this_file );

    return Path::Class::Dir->new( $dir, $this->boxdir );
}

sub path_local : method
{
    my $this = shift;

    
return "$FindBin::Bin";
}

sub request : method
{
    my $this = shift;

    my $name = shift;

    my $path = shift;


    if( not defined($path) )
    {
	$path = $this->path_home;
    }
    elsif( $path =~ /^__/ )
    {
	$path =~ s/^__//;

	if( exists $this->env->{$path} )
	{
	    $path = $this->env->{$path};
	}
	else
	{
	    Carp::croak "$this->request: Not in 'env': '$path'. Already in 'env' are only ", join( ', ', keys %{ $this->env } );

	      return undef;
	}
    }

    Carp::croak 'only FILE|SCALAR are allowed for type' and return undef unless $path;

return Path::Class::File->new( $path, $name );
}

1;

__END__

=head1 NAME

File::Box - Perl extension for blah blah blah

=head1 SYNOPSIS

  use File::Box;

  package Whatever;

   my $box = File::Box->new( mother_file => __FILE__, env => { SOURCE => '/home/path/src' } );

    # default 'boxdir' is under the module path is '.box'

    # 'env' registers path's used with 'request' below. Names are identified by an heading '__'.

    # ie. /home/Murat/checkout/perl/modules/File-Box/blib/lib/File/Box/.box
   println $box->path_home;

    # ie. path where the perl 'binary' has been called
   println $box->path_local;

    # ie. serve from path defined in 'env'; HOME and LOCAL are automatically created  

    # HOME is actually default, so next two calls will be identical
   println $box->request( 'bla.txt' );
   println $box->request( 'bla.txt', '__HOME' );

   println $box->request( 'bla.txt', '__LOCAL' );
   println $box->request( 'bla.txt', '__SOURCE' );

   # MyPath will be handled as the absolute path 
   println $box->request( 'bla.txt', 'MyPath' );

   println "failure causes undef !" if $box->request( 'bla.txt', '__UNKNOWN' );

=head1 DESCRIPTION

File::Box serves file path's. It was created to help serving non-module files (like textfiles/templates) 
in perl module directories and alike.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Regexp::Box

=head1 AUTHOR

M. Uenalan, E<lt>muenalan@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by M. Uenalan

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut

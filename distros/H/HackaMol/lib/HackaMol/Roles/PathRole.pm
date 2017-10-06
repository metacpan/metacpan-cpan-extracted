package HackaMol::Roles::PathRole;
$HackaMol::Roles::PathRole::VERSION = '0.045';
#ABSTRACT:  
use 5.008;
use Moose::Role;
use MooseX::Types::Path::Tiny qw/Path Paths AbsPath AbsPaths/;

has 'in_fn' => (
    is        => 'rw',
    isa       => Path,
    coerce    => 1,
    predicate => 'has_in_fn', 
);
 
has 'out_fn' => (
    is        => 'rw',
    isa       => Path,
    coerce    => 1,
    predicate => 'has_out_fn', 
);

has 'err_fn' => (
    is        => 'rw',
    isa       => Path,
    coerce    => 1,
    predicate => 'has_err_fn',
);

has 'log_fn' => (
    is       => 'rw',
    isa      => Path,
    coerce   => 1,
    predicate => 'has_log_fn', 
); 

has 'forts' => (
    is       => 'ro',
    isa      => Paths,
    coerce   => 1,
    predicate => 'has_forts', 
);

has 'homedir' => (
    is       => 'ro',
    isa      => AbsPath,
    coerce   => 1,
    default  => '.',
);
 
has 'scratch' => (
    is       => 'ro',
    isa      => AbsPath,
    coerce   => 1,
    predicate => 'has_scratch', 
);

has 'data' => (
    is       => 'ro',
    isa      => AbsPath,
    coerce   => 1,
    predicate => 'has_data', 
); 

has 'dirs' => (
    is       => 'ro',
    isa      => AbsPaths,
    coerce   => 1,
    predicate => 'has_dirs', 
); 

no Moose::Role;

1;

__END__

=pod

=head1 NAME

HackaMol::Roles::PathRole -  

=head1 VERSION

version 0.045

=head1 DESCRIPTION

This role adds some file and directory attributes to a class. This is still 
a work in progress, and it will probably change (suggestions welcome).  The 
goal is to reduce the amount code required for manipulating file and directory
paths used for work, and to allow scripts to be more platform independent. 
MooseX::Types::Path::Tiny is used to coerce the attributes into Path::Tiny
objects. See Path::Tiny for associated methods.  The actual construction of 
directories is left to scripts and extensions. 

=head1 ATTRIBUTES

=head2 scratch homedir data 

isa Path::Tiny coerced via AbsPath that is 'ro'  

the absolute path to the directory is constructed

=head2 log_fn in_fn out_fn err_fn 

isa Path::Tiny coerced via Path that is 'rw'   

=head2 dirs 

isa ArrayRef[Path::Tiny] coerced via AbsPaths that is 'ro'

fill your object with all the directories you wish

  my $obj = SomeClass->new(dirs = [qw/. .. data tmp \/var ~\/bin/]

=head2 forts

isa ArrayRef[Path::Tiny] coerced via Paths that is 'ro'

a place for those extra files

=head1 AUTHOR

Demian Riccardi <demianriccardi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Demian Riccardi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

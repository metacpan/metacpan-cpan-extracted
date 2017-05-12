#-----------------------------------------------------------------
# MOSES::MOBY::Generators::GenTypes
# Author: Martin Senger <martin.senger@gmail.com>,
#         Edward Kawas <edward.kawas@gmail.com>
#
# For copyright and disclaimer see below.
#
# $Id: GenTypes.pm,v 1.4 2008/04/29 19:42:56 kawas Exp $
#-----------------------------------------------------------------

package MOSES::MOBY::Generators::GenTypes;
use MOSES::MOBY::Base;
use base qw( MOSES::MOBY::Base );
use Template;
use FindBin qw( $Bin );
use lib $Bin;
use File::Spec;
use MOSES::MOBY::Cache::Central;
use MOSES::MOBY::Generators::Utils;
use vars qw( %PRIMITIVE_TYPES );
use strict;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/;

#-----------------------------------------------------------------
# A list of allowed attribute names. See MOSES::MOBY::Base for details.
#-----------------------------------------------------------------
{
    my %_allowed =
	(
	 outdir     => undef,
	 cachedir   => undef,
	 registry   => undef,
	 );

    sub _accessible {
	my ($self, $attr) = @_;
	exists $_allowed{$attr} or $self->SUPER::_accessible ($attr);
    }
    sub _attr_prop {
	my ($self, $attr_name, $prop_name) = @_;
	my $attr = $_allowed {$attr_name};
	return ref ($attr) ? $attr->{$prop_name} : $attr if $attr;
	return $self->SUPER::_attr_prop ($attr_name, $prop_name);
    }
}

#-----------------------------------------------------------------
# init
#-----------------------------------------------------------------
sub init {
    my ($self) = shift;
    $self->SUPER::init();
    $self->cachedir ($MOBYCFG::CACHEDIR);
    $self->registry ($MOBYCFG::REGISTRY);
    $self->outdir ( $MOBYCFG::GENERATORS_OUTDIR ||
		    MOSES::MOBY::Generators::Utils->find_file ($Bin, 'generated') );
}

#-----------------------------------------------------------------
# Check boolean value of a string.
#-----------------------------------------------------------------
sub _is {
    my $value = shift;
    return ($value =~ /true|\+|1|yes|ano/ ? '1' : '');
}

#-----------------------------------------------------------------
# I do not generate primitive types
#-----------------------------------------------------------------
%PRIMITIVE_TYPES = ( Object => 1,  Integer => 1,  Boolean  => 1,
		     String => 1,  Float   => 1,  DateTime => 1 );

#-----------------------------------------------------------------
# generate
#-----------------------------------------------------------------
sub generate {
    my ($self, @args) = @_;
    my %args =
	( # some default values
	  outdir     => $self->outdir,
	  cachedir   => $self->cachedir,
	  registry   => $self->registry,
	  with_docs  => 0,

	  # potential args with no default values
	  # obtain_related => 1 | 0,
	  # datatype_names => ['datatype1', 'datatype2', ...]
	  # outcode        => ref SCALAR

	  # and the real parameters
	  @args );

    $args{obtain_related} = $args{datatype_names} ? 1 : 0
	unless defined $args{obtain_related};

    $self->throw ("Parameter 'outcode' should be a reference to a SCALAR.")
	if $args{outcode} and ref ($args{outcode}) ne 'SCALAR';

    # get objects from a local cache
    my $cache = MOSES::MOBY::Cache::Central->new (cachedir => $args{cachedir},
					   registry => $args{registry});
    my @wanted_objs = ();

    # which 'top-level' objects we want
    $args{datatype_names} = [ $cache->get_datatype_names ]
	unless $args{datatype_names};
    foreach my $name (@{ $args{datatype_names} }) {
	push (@wanted_objs, $cache->get_datatype ($name));
    }

    # also we want all related objects
    @wanted_objs = @{ $cache->get_related_types (@wanted_objs)}
	if $args{obtain_related};

    # generate from template
    my $tt = Template->new ( ABSOLUTE => 1 );
    my $input = File::Spec->rel2abs ( MOSES::MOBY::Generators::Utils->find_file
				      ($Bin,
				       'MOSES', 'MOBY', 'Generators', 'templates',
				       'datatype.tt') );
    # where to generate
    my $outdir = File::Spec->rel2abs
	( ( $args{outdir} ?
	    $args{outdir} :
	    MOSES::MOBY::Generators::Utils->find_file ($Bin, 'generated') ) );
    $LOG->info ("Data types will be generated into: '$outdir'")
	unless $args{outcode};

    # generate even when it exists?
    my $ignore_existing = $MOBYCFG::GENERATORS_IGNORE_EXISTING_TYPES || 0;
    $ignore_existing = _is ($ignore_existing);
    $LOG->debug ("Ignoring pre-generated data types")
	if $ignore_existing;

    foreach my $obj (@wanted_objs) {
	next if exists $PRIMITIVE_TYPES{$obj->name};
	my $module_name = $obj->module_name;
	if ($args{outcode}) {
	    # check if the same data type is already loaded
	    next if eval '%' . $module_name . '::';
	    # check if the same data type is available pre-generated
	    eval "require $module_name" and next
		unless $ignore_existing;
	    $LOG->debug ("$module_name will be loaded");
	    $tt->process ( $input, { obj         => $obj,
				     full_source => $args{with_docs},
				 },
			   $args{outcode} ) || $LOG->logdie ($tt->error());
	} else {
	    $LOG->debug ("$module_name will be generated");
	    # we cannot easily check whether the same file was already
	    # generated - so we don't
	    my $outfile = (File::Spec->catfile ($outdir, 'MOSES', 'MOBY', 'Data',
						$self->module_name_escape ($obj->name) . '.pm'));
	    $tt->process ( $input, { obj         => $obj,
				     full_source => 1,
				 },
			   $outfile ) || $LOG->logdie ($tt->error());
	}
    }
}

#-----------------------------------------------------------------
# load
#    load (datatype-name)
#    load ([@datatype_names])
#    load (cachedir => dir, datatype_names => [..], ... )
#-----------------------------------------------------------------
sub load {
    my ($self, @args) = @_;
    @args = (datatype_names => $args[0])
	if ref ($args[0]) eq 'ARRAY';
    @args = (datatype_names => [ $args[0] ])
	if @args == 1 and !ref ($args[0]);

    my $code = '';
    $self->generate (@args, outcode => \$code, obtain_related => 1);
    eval $code;
    $LOG->logdie ("$@") if $@;
}

1;
__END__

=head1 NAME

MOSES::MOBY::Generators::GenTypes - generator of Moby data types

=head1 SYNOPSIS

 use MOSES::MOBY::Generators::GenTypes;
 
=head1 DESCRIPTION

=head1 AUTHORS, COPYRIGHT, DISCLAIMER

 Martin Senger (martin.senger [at] gmail [dot] com)
 Edward Kawas (edward.kawas [at] gmail [dot] com)

Copyright (c) 2006 Martin Senger, Edward Kawas. All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This software is provided "as is" without warranty of any kind.

=head1 ACCESSIBLE ATTRIBUTES

Details are in L<MOSES::MOBY::Base>. Here just a list of them:

=over

=item B<outdir>

A directory where to create generated code.

=item B<cachedir>

=item B<registry>

=back

=head1 SUBROUTINES

#-----------------------------------------------------------------
# generate
#
# with_docs:
# A boolean property. If set to true the generated code includes also
# Perl documentation. If set to false then the documentation is
# generated only when output is directed to a file (it would be
# dangerous to have it inside code that is evaluated when more data
# types are generated in the same time).
#-----------------------------------------------------------------

#-----------------------------------------------------------------
# load
#    load (datatype-name)
#    load ([@datatype_names])
#    load (cachedir => dir, datatype_names => [..], ... )
#-----------------------------------------------------------------

=cut


# -------------------------------------------------------------------------------------
# MKDoc::XML::Decode
# -------------------------------------------------------------------------------------
# Author : Jean-Michel Hiver
# Copyright : (c) MKDoc Holdings Ltd, 2003
#
# This modules expands XML entities &amp; &gt; &lt; &quot; and &apos;.
#
# This module is distributed under the same license as Perl itself.
# -------------------------------------------------------------------------------------
package MKDoc::XML::Decode;
use warnings;
use strict;


our %Modules = ();

our $WARN    = 0;


# import all plugins once
foreach my $include_dir (@INC)
{
    my $dir = "$include_dir/MKDoc/XML/Decode";
    if (-e $dir and -d $dir)
    {
        opendir DD, $dir or do {
            warn "Cannot open directory $dir. Reason: $!";
            next;
        };
	
        my @modules = map { s/\.pm$//; $_ }
                      grep /\.pm$/,
                      grep !/^\./,
                      readdir (DD);

        closedir DD;
	
        foreach my $module (@modules)
        {
	    $module =~ /^(\w+)$/;
	    $module = $1;
	    eval "use MKDoc::XML::Decode::$module";
            $@ and warn "Cannot import module $module. Reason: $@";
	    
	    my $name = "MKDoc::XML::Decode::$module"->can ('module_name') ?
	               "MKDoc::XML::Decode::$module"->module_name() :
		       lc ($module);
	    
	    $Modules{$name} = "MKDoc::XML::Decode::$module";
        }
    }
}


sub new
{
    my $class = shift;
    @_ = sort keys %Modules unless (scalar @_);
    
    my $self  = bless [ map {
	$Modules{$_} ? $Modules{$_} : do {
	    warn "Module $_ not found - Ignoring";
	    ();
	} } @_ ], $class;

    return $self;
}


sub entity_to_char
{
    my $self = shift;
    my $char = shift;
    for (@{$self}) {
	my $res = $_->process ($char);
	return $res if (defined $res);
    };
    
    warn "Could not expand &$char;" if ($WARN);
    return "&$char;";
}


sub process
{
    (@_ == 2) or warn "MKDoc::XML::Encode::process() should be called with two arguments";

    my $self = shift;
    my $data = join '', map { defined $_ ? $_ : () } @_;
    $data    =~ s/&(#?[0-9A-Za-z]+);/$self->entity_to_char ($1)/eg;
    return $data;
}


1;


__END__


=head1 NAME

MKDoc::XML::Decode - Expands XML entities


=head1 SYNOPSIS

  use MKDoc::XML::Decode;
  my $decode = new MKDoc::XML::Decode qw/xml xhtml numeric/;

  # $xml is now "Chris' Baloon"
  my $xml = MKDoc::XML::Decode->process ("Chris&apos; Baloon");


=head1 SUMMARY

MKDoc::XML::Decode is a very simple module with pluggable entity decoding mechanism.
At the moment there are three modules:

xml     - Decodes &apos; &quot; &gt; &lt; and &amp;
xhtml   - Decodes XHTML entities such as &eacute;
numeric - Decodes numeric entities such as &#65;

That's it.

This module and its counterpart L<MKDoc::XML::Encode> are used by L<MKDoc::XML::Dumper>
to XML-encode and XML-decode litterals.


=head1 API

=head2 my $decode_object = new MKDoc::XML::Decode (@modules);

Constructs a new decode object using the modules specified in @modules.

=head2 my $decoded = $decode_object->decode ($stuff);

Decodes $stuff and returns it into $decoded.

Any entity which is not recognized will be returned as is but will trigger a warning.


=head1 AUTHOR

Copyright 2003 - MKDoc Holdings Ltd.

Author: Jean-Michel Hiver

This module is free software and is distributed under the same license as Perl
itself. Use it at your own risk.


=head1 SEE ALSO

L<MKDoc::XML::Encode>

=cut

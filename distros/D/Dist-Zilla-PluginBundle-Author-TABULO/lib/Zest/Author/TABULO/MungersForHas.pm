
use strict;
use warnings;

package Zest::Author::TABULO::MungersForHas;
our $VERSION = '1.000014';

use Exporter::Shiny qw(
    hm_tabulo
    hm_lazy_if_possible
    hm_enhance_documentation
    hm_strip_nonstandard_opts
);


#region: #== HAS-MUNGERS ==

##== High level: Apply our own suite of mungers for MooseX::MungeHas
sub hm_tabulo {

  ## no critic: Subroutines::ProhibitAmpersandSigils
  &hm_lazy_if_possible;
  &hm_enhance_documentation;
  &hm_strip_nonstandard_opts;
}

##== Lower level: Individual mungers for MooseX::MungeHas

sub hm_lazy_if_possible {
    unless ( exists $_{lazy} && defined $_{lazy} ) {
        $_{lazy} //= 1 if exists $_{default} || exists $_{builder};
    }
}

sub hm_enhance_documentation {

    #local %_ = ( name => $name, %opt ); # %_ will be available in CODE, filled with whatever we have for attribute META

    # Semi-dynamic documentation (with rudimentary templating)
    $_{-document_default} = sub { "Default: '$_{default}'" }
      if delete $_{-document_default} // 1 and exists $_{default} and defined $_{default} and !ref $_{default};

    for my $key (qw(documentation -doc -document_default)) {
        my $doc = delete $_{$key} // next;
        $doc     = $doc->() if ref($doc) =~ /CODE/;
        $_{$key} = $doc     if defined $doc;
    }
    my $doc = join( " ", delete $_{-doc} // (), delete $_{-document_default} // () );
    $_{documentation} //= $doc if $doc;
}

sub hm_strip_nonstandard_opts {
    %_ = ( map { ( $_->key =~ m/^-/ ) ? () : (@$_) } List::Util::pairs(%_) );
}


#endregion HAS-MUNGERS

1;

=pod

=encoding UTF-8

=for :stopwords Tabulo[n]

=head1 NAME

Zest::Author::TABULO::MungersForHas - Utility functions used by TABULO's authoring dist

=head1 VERSION

version 1.000014

=for Pod::Coverage hm_enhance_documentation  hm_lazy_if_possible  hm_strip_nonstandard_opts  hm_tabulo

=head1 AUTHORS

Tabulo[n] <dev@tabulo.net>

=head1 LEGAL

This software is copyright (c) 2023 by Tabulo[n].

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#ABSTRACT: Utility functions used by TABULO's authoring dist

## TODO: Actually document some of the below

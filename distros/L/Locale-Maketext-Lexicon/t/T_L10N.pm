# Test localization class and its subclasses
# Copyright (c) 2003 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

package T_L10N;

use strict;
use FindBin;
use File::Spec;
use base qw(Locale::Maketext);

my (%Domains, $Domain);
sub bindtextdomain {
    my ($self, $domain, $dir) = @_;
    return $Domains{$domain} unless $dir;
    $Domains{$domain} = $dir;

    require Locale::Maketext::Lexicon;
    Locale::Maketext::Lexicon->import({
	'*' => [
	    Gettext => File::Spec->catdir( $dir, qw(* LC_MESSAGES), "$domain.mo" )
	],
	_decode => 1,
    });
}

sub textdomain {
    my ($self, $domain) = @_;
    $Domain = $domain if $domain;
    return $Domain;
}

sub readmo {
    my ($self, $file) = @_;
    local ($/, *FH);
    open FH, $file;
    binmode(FH);

    require Locale::Maketext::Lexicon::Gettext;
    my $hashref = Locale::Maketext::Lexicon::Gettext::parse_mo(<FH>);
    delete @{$hashref}{grep /^__/, keys %$hashref};
    return Locale::Maketext::Lexicon::Gettext->input_encoding, %$hashref;
}

sub encoding {
    my ($self, $encoding) = @_;

    if ($encoding) {
	$self->{CUR_ENC} = $encoding;
    }
    elsif ( !$self->{CUR_ENC} ) {
	$self->{CUR_ENC} = $1
	    if $self->SUPER::maketext('__Content-Type') =~ /\bcharset=\s*([-\w]+)/i;
    }

    $self->{CUR_ENC};
}

sub maketext {
    my $self = shift;

    require Encode::compat if ($] == 5.006001);
    require Encode;
    Encode::encode($self->encoding, $self->SUPER::maketext(@_));
}

1;

package T_L10N::en;
use base qw(T_L10N);

1;

package T_L10N::zh_tw;
use base qw(T_L10N);

1;

package T_L10N::zh_cn;
use base qw(T_L10N);

1;

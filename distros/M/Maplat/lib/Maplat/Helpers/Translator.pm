# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Helpers::Translator;
use strict;
use warnings;

use 5.012;

use Maplat::Helpers::DBSerialize;

# Translations and caching

use base qw(Exporter);
our @EXPORT = qw(tr_reload tr_checklang tr_rememberkey tr_translate tr_export tr_import); ## no critic (Modules::ProhibitAutomaticExportation)
our $VERSION = 0.995;

use YAML::Syck;
use Carp;

sub tr_reload {
    my ($dbh, $memh) = @_;

    my $lsth = $dbh->prepare_cached("SELECT lang FROM translate_languages")
        or croak($dbh->errstr);
    my $ksth = $dbh->prepare_cached("SELECT originaltext FROM translate_keys")
        or croak($dbh->errstr);
    my $tsth = $dbh->prepare_cached("SELECT originaltext, translation FROM translate_translations WHERE lang = ?")
        or croak($dbh->errstr);

    my %translate;
    
    my @langs;
    $lsth->execute or croak($dbh->errstr);
    while((my $lang = $lsth->fetchrow_array)) {
        push @langs, $lang;
    }
    $lsth->finish;
    $translate{langs} = \@langs;
    
    my @keys;
    $ksth->execute or croak($dbh->errstr);
    while((my $key = $ksth->fetchrow_array)) {
        push @keys, $key;
    }
    $ksth->finish;
    $translate{keys} = \@keys;
    
    foreach my $lang (@langs) {
        my %trans;
        $tsth->execute($lang) or croak($dbh->errstr);
        while((my $line = $tsth->fetchrow_hashref)) {
            $trans{$line->{originaltext}} = $line->{translation};
        }
        $tsth->finish;
        $translate{lang}->{$lang} = \%trans;
    }
    
    $memh->set("LanguageCache", \%translate);
    return;
}

sub tr_checklang {
    my ($memh, $lang) = @_;

    my $translate = $memh->get("LanguageCache");
    
    if($lang ~~ @{$translate->{langs}}) {
        return 1;
    } else {
        return 0;
    }

}

sub tr_rememberkey {
    my ($dbh, $memh, $key) = @_;

    my $translate = $memh->get("LanguageCache");
    
    if($key ~~ @{$translate->{keys}}) {
        return;
    }
    
    my $sth = $dbh->prepare("SELECT insert_translatekey(?)")
            or croak($dbh->errstr);
    if(!$sth->execute($key)) {
        $dbh->rollback;
    } else {
        $dbh->commit;
        tr_reload($dbh, $memh);
    }
    return;

}

sub tr_translate {
    my ($dbh, $memh, $lang, $key) = @_;

    my $translate = $memh->get("LanguageCache");
    
    if($key ~~ @{$translate->{keys}}) {
        if(defined($translate->{lang}->{$lang}) &&
               defined($translate->{lang}->{$lang}->{$key})) {
            return $translate->{lang}->{$lang}->{$key};
        } else {
            return $key;
        }
    }
    
    my $sth = $dbh->prepare("SELECT insert_translatekey(?)")
            or croak($dbh->errstr);
    if(!$sth->execute($key)) {
        $dbh->rollback;
    } else {
        $dbh->commit;
        tr_reload($dbh, $memh);
    }
    return $key;
}

sub tr_export {
    my ($dbh, $memh) = @_;
    tr_reload($dbh, $memh);
    
    my $translate = $memh->get("LanguageCache");
    
    my $exp = dbfreeze($translate);
    
    return $exp;
}

sub tr_import {
    my ($dbh, $memh, $impraw) = @_;
    tr_reload($dbh, $memh);
    
    my $translate = $memh->get("LanguageCache");
    
    my $imp = dbthaw($impraw);
    
    my $limpsth = $dbh->prepare("INSERT INTO translate_languages
                                             (lang, description)
                                             VALUES (?,'')")
            or croak($dbh->errstr);

    my $kimpsth = $dbh->prepare("SELECT insert_translatekey(?)")
            or croak($dbh->errstr);

    my $upsth = $dbh->prepare("SELECT merge_translation(?, ?, ?)")
            or croak($dbh->errstr);

    # Insert missing languages
    $imp = dbderef($imp);
    foreach my $lang (@{$imp->{langs}}) {
        if(!($lang ~~ @{$translate->{langs}})) {
            $limpsth->execute($lang) or croak($dbh->errstr);
        }
    }
    
    # Insert all keys
    foreach my $key (@{$imp->{keys}}) {
        $kimpsth->execute($key) or croak($dbh->errstr);
    }
    
    # Now, merge all new translations
    foreach my $lang (@{$imp->{langs}}) {
        # $translate{lang}->{$lang}
        foreach my $orig (keys %{$imp->{lang}->{$lang}}) {
            my $trans = $imp->{lang}->{$lang}->{$orig};
            $upsth->execute($orig, $lang, $trans)
                or croak($dbh->errstr);
        }
    }
    $dbh->commit;
    
    tr_reload($dbh, $memh);
    
    return;
}

1;
__END__

=head1 NAME

Maplat::Helpers::Translator - helper for multilanguage support

=head1 SYNOPSIS

  use Maplat::Helpers::Translator;
  
=head1 DESCRIPTION

This module is an internal helper for multilanguage support

=head2 tr_checklang

Internal function

=head2 tr_export

Internal function

=head2 tr_import

Internal function

=head2 tr_reload

Internal function

=head2 tr_rememberkey

Internal function

=head2 tr_translate

Internal function

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

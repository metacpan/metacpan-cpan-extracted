# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::Translate;
use strict;
use warnings;

use 5.012;


use base qw(Maplat::Web::BaseModule);
use Maplat::Helpers::DateStrings;
use Maplat::Helpers::DBSerialize;
use Maplat::Web::TT::Translate;
use Maplat::Helpers::Translator;
use Maplat::Helpers::FileSlurp qw(slurpBinFile);

our $VERSION = 0.995;

use Carp;
use Readonly;
Readonly my $TESTRANGE => 1_000_000;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class
    
    my @themes;
    foreach my $key (sort keys %{$self->{view}}) {
        my %theme = %{$self->{view}->{$key}};
        $theme{name} = $key;
        
        push @themes, \%theme;
    }
    $self->{Themes} = \@themes;
    $self->{firstReload} = 1;
    
    return $self;
}

sub reload {
    my ($self) = shift;

    # Update the handles for the template plugin
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};

    if($self->{firstReload}) {
        $self->{firstReload} = 0;
        Maplat::Web::TT::Translate->setDBH($dbh);
        Maplat::Web::TT::Translate->setMEMH($memh);
    }
    tr_reload($dbh, $memh);

    return;
}

sub register {
    my $self = shift;
    $self->register_webpath($self->{settings}->{webpath}, "get_settings");
    $self->register_webpath($self->{languages}->{webpath}, "get_languages");
    $self->register_webpath($self->{translations}->{webpath}, "get_translations");
    $self->register_webpath($self->{export}->{webpath}, "get_export");
    $self->register_webpath($self->{exportfile}->{webpath}, "get_file");
    $self->register_prerender("prerender");
    return;
}

sub get_settings {
    my ($self, $cgi) = @_;
    
    my $webpath = $cgi->path_info();
    my $seth = $self->{server}->{modules}->{$self->{usersettings}};
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    
    my @AvailLangs;
    my $sth = $dbh->prepare_cached("SELECT * FROM translate_languages
                                   ORDER BY lang")
            or croak($dbh->errstr);
    $sth->execute or croak($dbh->errstr);
    while((my $lang = $sth->fetchrow_hashref)) {
        push @AvailLangs, $lang;
    }
    $sth->finish;
    
    my %webdata =
    (
        $self->{server}->get_defaultwebdata(),
        PageTitle       =>  $self->{settings}->{pagetitle},
        webpath         =>  $self->{settings}->{webpath},
        AvailLanguages  =>  \@AvailLangs,
    );    
    
    # We don't actually set the Theme into webdata here, this is done during the prerender stage.
    # Also, we don't handle the "select a default theme if non set" case, TemplateCache falls back to
    # its own default theme anyway
    my $mode = $cgi->param('mode') || 'view';
    if($mode eq "setvalue") {
        my $lang = $cgi->param('language') || "eng";
        if($lang ne "") {
            $seth->set($webdata{userData}->{user}, "UserLanguage", \$lang);
        }
    }

    my $template = $self->{server}->{modules}->{templates}->get("translate_select", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}

sub get_languages {
    my ($self, $cgi) = @_;
    
    my $webpath = $cgi->path_info();
    my $seth = $self->{server}->{modules}->{$self->{usersettings}};
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    
    my %webdata =
    (
        $self->{server}->get_defaultwebdata(),
        PageTitle       =>  $self->{languages}->{pagetitle},
        webpath         =>  $self->{languages}->{webpath},
    );    
    
    my $mode = $cgi->param('mode') || 'view';
    
    given($mode) {
        when("change") {
            my $upsth = $dbh->prepare_cached("UPDATE translate_languages
                                             SET lang = ?, description = ?
                                             WHERE lang = ?")
                    or croak($dbh->errstr);
            my $oldlang = $cgi->param('language') || '';
            my $newlang = $cgi->param('newlanguage') || '';
            my $description = $cgi->param('description') || '';
            if($oldlang ne '' && $newlang ne '') {
                if($upsth->execute($newlang, $description, $oldlang)) {
                    $dbh->commit;
                } else {
                    $dbh->rollback;
                }
            }
        }
        when("delete") {
            my $delsth = $dbh->prepare_cached("DELETE FROM translate_languages
                                             WHERE lang = ?")
                    or croak($dbh->errstr);
            my $oldlang = $cgi->param('language') || '';
            if($oldlang ne '') {
                if($delsth->execute($oldlang)) {
                    $dbh->commit;
                } else {
                    $dbh->rollback;
                }
            }
        }
        when("create") {
            my $insth = $dbh->prepare_cached("INSERT INTO translate_languages
                                             (lang, description)
                                             VALUES (?,?)")
                    or croak($dbh->errstr);
            my $newlang = $cgi->param('newlanguage') || '';
            my $description = $cgi->param('description') || '';
            if($newlang ne '') {
                if($insth->execute($newlang, $description)) {
                    $dbh->commit;
                } else {
                    $dbh->rollback;
                }
            }
        }
    }
    
    my @AvailLangs;
    my $sth = $dbh->prepare_cached("SELECT * FROM translate_languages
                                   ORDER BY lang")
            or croak($dbh->errstr);
    $sth->execute or croak($dbh->errstr);
    while((my $lang = $sth->fetchrow_hashref)) {
        push @AvailLangs, $lang;
    }
    $sth->finish;
    $webdata{AvailLanguages} = \@AvailLangs;

    my $template = $self->{server}->{modules}->{templates}->get("translate_languages", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}

sub get_translations {
    my ($self, $cgi) = @_;
    
    my $webpath = $cgi->path_info();
    my $seth = $self->{server}->{modules}->{$self->{usersettings}};
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    
    my @AvailLangs;
    my $sth = $dbh->prepare_cached("SELECT * FROM translate_languages
                                   ORDER BY lang")
            or croak($dbh->errstr);
    $sth->execute or croak($dbh->errstr);
    while((my $lang = $sth->fetchrow_hashref)) {
        push @AvailLangs, $lang;
    }
    $sth->finish;
    
    my %webdata =
    (
        $self->{server}->get_defaultwebdata(),
        PageTitle       =>  $self->{translations}->{pagetitle},
        webpath         =>  $self->{translations}->{webpath},
        AvailLanguages  =>  \@AvailLangs,
    );    
    
    my ($ok, $langname) = $seth->get($webdata{userData}->{user}, "EditLanguage");
    
    my $lang = "eng"; # Use english as default
    if(defined($langname)) {
        $langname = dbderef($langname);
    }
    if($ok && defined($langname) && $langname ne "") {
        $lang = $langname;
    }    
    
    my $mode = $cgi->param('mode') || 'view';
    given($mode) {
        when("setlanguage") {
            $lang = $cgi->param('language') || "eng";
            $seth->set($webdata{userData}->{user}, "EditLanguage", \$lang);
        }
        when("change") {
            my @keys = $cgi->param('originaltext');
            my $upsth = $dbh->prepare("SELECT merge_translation(?, ?, ?)")
                    or croak($dbh->errstr);
            foreach my $key (@keys) {
                my $translation = $cgi->param("translate_$key") || '';
                if($upsth->execute($key, $lang, $translation)) {
                    $dbh->commit;
                } else {
                    $dbh->rollback;
                }
            }
            tr_reload($dbh, $memh);
        }
    }
    
    $webdata{EditLanguage} = $lang;
    
    my @trLines;
    my $selsth = $dbh->prepare_cached("SELECT k.originaltext, t.translation
                                   FROM translate_keys k
                                   LEFT OUTER JOIN translate_translations t
                                    ON (k.originaltext = t.originaltext)
                                    AND t.lang = ?
                                    ORDER BY originaltext")
            or croak($dbh->errstr);
    $selsth->execute($lang) or croak($dbh->errstr);
    while((my $line = $selsth->fetchrow_hashref)) {
        if(!defined($line->{translation})) {
            $line->{translation} = '';
        }
        push @trLines, $line;
    }
    $selsth->finish;
    $webdata{trLines} = \@trLines;

    my $template = $self->{server}->{modules}->{templates}->get("translate_translate", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}










sub get_export {
    my ($self, $cgi) = @_;
    
    my $webpath = $cgi->path_info();
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    
    my @AvailLangs;
    my $sth = $dbh->prepare_cached("SELECT * FROM translate_languages
                                   ORDER BY lang")
            or croak($dbh->errstr);
    $sth->execute or croak($dbh->errstr);
    while((my $lang = $sth->fetchrow_hashref)) {
        push @AvailLangs, $lang;
    }
    $sth->finish;
    
    my %webdata =
    (
        $self->{server}->get_defaultwebdata(),
        PageTitle       =>  $self->{export}->{pagetitle},
        webpath         =>  $self->{export}->{webpath},
        AvailLanguages  =>  \@AvailLangs,
    );    
    
    
    my $mode = $cgi->param('mode') || 'view';
    given($mode) {
        when("import") {
            my $fh = $cgi->upload("filename");
            my $data;
            if($fh) {
                while((my $line = <$fh>)) {
                    $data .= $line;
                }
                tr_import($dbh, $memh, $data);
            }
        }
    }
    
    $webdata{ExportFile} = $self->{exportfile}->{webpath}. "/EXPORT" . int(rand($TESTRANGE) + 1) . "." . int(rand($TESTRANGE) + 1) . ".txt";
    
    my $template = $self->{server}->{modules}->{templates}->get("translate_export", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}


sub get_file {
    my ($self, $cgi) = @_;
    
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};

    my $exp = tr_export($dbh, $memh);

    return (status  =>  404) unless $exp;
    return (status  =>  200,
            type    => "text/plain",
            "Content-Disposition" => "attachment; filename=\"translations_export.txt\";",
            data    => $exp);
}


sub prerender {
    my ($self, $webdata) = @_;
    
    # Unless the user is logged in, we don't have set a user selected Language, use English
    if(!defined($webdata->{userData}) ||
              !defined($webdata->{userData}->{user}) ||
              $webdata->{userData}->{user} eq "") {
        $webdata->{UserLanguage} = "eng";
        Maplat::Web::TT::Translate->setLang("eng");
    }
    
    my $seth = $self->{server}->{modules}->{$self->{usersettings}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    my ($ok, $langname) = $seth->get($webdata->{userData}->{user}, "UserLanguage");
    
    my $lang = "eng"; # Use english as default
    if(defined($langname)) {
        $langname = dbderef($langname);
    }
    if($ok && defined($langname) && $langname ne "") {
        # Now, we have to check if this theme is still available
        
        # FIXME: Check if language still available!
        if(tr_checklang($memh, $langname)) {
            $lang = $langname;
        }

    }

    $webdata->{UserLanguage} = $lang;
    Maplat::Web::TT::Translate->setLang($lang);

    return;
}

1;
__END__

=head1 NAME

Maplat::Web::Translate - add multilanguage support to your project

=head1 SYNOPSIS

Adds multilanguage support for the web projects.

=head1 DESCRIPTION

This module adds various hooks to the system as well as managment of all translations
via webpages.

=head1 Configuration

    <module>
        <modname>translate</modname>
        <pm>Translate</pm>
        <options>
            <memcache>realmemcache</memcache>
            <db>maindb</db>
            <memdb>memdb</memdb>
            <usersettings>usersettings</usersettings>
            <languages>
                <webpath>/admin/languages</webpath>
                <pagetitle>Languages</pagetitle>
            </languages>
            <translations>
                <webpath>/admin/translate</webpath>
                <pagetitle>Translations</pagetitle>
            </translations>
            <settings>
                <webpath>/settings/language</webpath>
                <pagetitle>Language</pagetitle>
            </settings>
            <export>
                <webpath>/admin/trexport</webpath>
                <pagetitle>Import/Export</pagetitle>
            </export>
            <exportfile>
                <webpath>/admin/trexpfile</webpath>
            </exportfile>
        </options>
    </module>

=head2 get_export

Import/Export mask

=head2 get_file

The actual file download for the export mask

=head2 get_languages

Manage languages through the web.

=head2 get_settings

Manage the user settings.

=head2 get_translations

Managne translated texts

=head2 prerender

Hook to properly set up the Template-Toolkit plugin before rendering.

=head1 SEE ALSO

Maplat::Web

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

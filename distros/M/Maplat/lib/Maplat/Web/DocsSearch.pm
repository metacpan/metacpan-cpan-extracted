# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::DocsSearch;
use strict;
use warnings;

use base qw(Maplat::Web::BaseModule);
use Maplat::Helpers::DateStrings;
use Maplat::Helpers::Strings 'normalizeString';

our $VERSION = 0.995;


use Carp;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class
        
    return $self;
}

sub reload {
    my ($self) = shift;
    # Nothing to do.. in here, we only use the template and database module
    return;
}

sub register {
    my $self = shift;
    $self->register_webpath($self->{webpath}, "get");
    return;
}

sub get {
    my ($self, $cgi) = @_;

    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $sesh = $self->{server}->{modules}->{$self->{session}};
    my @availLang = ('English', 'German');
    
    my ($ok, $selectedLang) = $sesh->get("SearchLanguage");
    if(!$ok) {
        $selectedLang = $availLang[0];
    }
    my $rawwords;
    ($ok, $rawwords) = $sesh->get("SearchTerms");
    if(!$ok) {
        $rawwords = "";
    }
    
        
    my %webdata = (
        $self->{server}->get_defaultwebdata(),
        PageTitle   =>  $self->{pagetitle},
        PostLink        =>  $self->{webpath},
        AvailLanguages => \@availLang,
    );
    
    my $mode = $cgi->param("mode") || "view";
    if($mode eq "search") {
        $selectedLang = $cgi->param("language") || $availLang[0];
        my $searchlang = lc($selectedLang);
        $sesh->set("SearchLanguage", $selectedLang);
        
        $rawwords = $cgi->param("searchterm") || "";
        $rawwords = normalizeString($rawwords);
        $sesh->set("SearchTerms", $rawwords);
        if($rawwords ne "") {
            my $keywords = join(' & ', split(/\W/, $rawwords));
            my $sth = $dbh->prepare_cached("SELECT id, username, doctype, filename,
                                                ts_headline('$searchlang', txtcontent, query) AS snippet,
                                                ts_rank_cd($searchlang\_tsearch, query) AS rank
                                                FROM documents, to_tsquery(?) query
                                                WHERE $searchlang\_tsearch \@\@ query
                                                ORDER BY rank desc
                                                LIMIT 10"
                                            )
                            or croak($dbh->errstr);
            my @lines;
            $sth->execute($keywords) or croak($dbh->errstr);
            while((my $line = $sth->fetchrow_hashref)) {
                $line->{graphrankact} = int($line->{rank} * 50);
                if($line->{graphrankact} > 200) {
                    $line->{graphrankact} = 200;
                }
                $line->{graphrankinact} = 200 - $line->{graphrankact};
                if($line->{doctype} eq "Word") {
                    $line->{link} = "/devtest/word/open/" . $line->{id};
                } elsif($line->{doctype} eq "Spreadsheet") {
                    $line->{link} = "/devtest/spread/list/" . $line->{id};
                }
                push @lines, $line;
            }
            $sth->finish;
            $webdata{SearchResults} = \@lines;
                
            $dbh->rollback;
        }
    }
    $webdata{SelectedLanguage} = $selectedLang;
    $webdata{SearchTerm} = $rawwords;
    
    my $template = $self->{server}->{modules}->{templates}->get("docssearch", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}

1;
__END__

=head1 NAME

Maplat::Web::DocsSearch - search mask for documents

=head1 SYNOPSIS

This module provides a simple search mask for documents.

=head1 DESCRIPTION

The modules DocsSpreadSheet and DocsWordProcessor provide document editing capabilities. This modules
provides the full text search for your documents.

Full text search is realized through the capabilities provided by PostgreSQL.

=head1 Configuration

        <module>
                <modname>docssearch</modname>
                <pm>DocsSearch</pm>
                <options>
                        <pagetitle>Search</pagetitle>
                        <webpath>/devtest/search</webpath>
                        <db>maindb</db>
                        <memcache>memcache</memcache>
                        <session>sessionsettings</session>
                </options>
        </module>

=head2 get

Handle the documents search form.

=head1 Dependencies

This module depends on the following modules beeing configured (the 'as "somename"'
means the key name in this modules configuration):

Maplat::Web::Memcache as "memcache"
Maplat::Web::PostgresDB as "db"
Maplat::Web::SessionSettings as "session"

=head1 SEE ALSO

Maplat::Web
Maplat::Web::SessionSettings
Maplat::Web::PostgresDB
Maplat::Web::Memcache
Maplat::Web::DocsSpreadSheet
Maplat::Web::DocsWordProcessor

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

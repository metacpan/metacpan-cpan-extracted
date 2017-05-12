# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::DocsWordProcessor;
use strict;
use warnings;
use 5.010;

use base qw(Maplat::Web::BaseModule);
use Maplat::Helpers::DateStrings;
use HTML::Parse;

# FIXME: HTML::FormatText is broken
#use HTML::FormatText;

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
    $self->register_webpath($self->{open}->{webpath}, "edit");
    $self->register_webpath($self->{list}->{webpath}, "list");
    return;
}

sub list {
    my ($self, $cgi) = @_;

    my $dbh = $self->{server}->{modules}->{$self->{db}};
    
    my %webdata = (
        $self->{server}->get_defaultwebdata(),
        PageTitle   =>  $self->{list}->{pagetitle},
        PostLink    =>  $self->{list}->{webpath},
    );
    
    my $mode = $cgi->param("mode") || "view";
    my $filename = $cgi->param("filename") || "";
    my $fileid = $cgi->param("fileid") || "";
    if(($mode eq "edit" || $mode eq "create" || $mode eq "update" || $mode eq "delete")
            && $filename eq "") {
        $mode = "view";
        $webdata{statustext} = "Need a Filename!";
        $webdata{statuscolor} = "errortext";
    }

    if(($mode eq "edit" || $mode eq "viewuserform" || $mode eq "update" || $mode eq "delete")
            && $fileid eq "") {
        $mode = "view";
        $webdata{statustext} = "Internal error: No file id!";
        $webdata{statuscolor} = "errortext";
    }

    
    if($mode eq "edit" || $mode eq "create" || $mode eq "viewuserform") {
        return $self->edit($cgi);
    }
    
    if($mode eq "update") {
        my $ispublic = $cgi->param("is_public") || "";
        if($ispublic eq "") {
            $ispublic = "false";
        } else {
            $ispublic = "true";
        }
        my $upsth = $dbh->prepare_cached("UPDATE documents
                                         SET updated = now(),
                                         filename = ?,
                                         is_public = ?
                                         WHERE id = ?")
                or croak($dbh->errstr);
        if(!$upsth->execute($filename, $ispublic, $fileid)) {
            $dbh->rollback;
            $webdata{statustext} = "Update failed!";
            $webdata{statuscolor} = "errortext";
        } else {
            $dbh->commit;
            $webdata{statustext} = "File settings updated";
            $webdata{statuscolor} = "oktext";
        }
    } elsif($mode eq "delete") {
        my $upsth = $dbh->prepare_cached("DELETE FROM documents
                                         WHERE id = ?")
                or croak($dbh->errstr);
        if(!$upsth->execute($fileid)) {
            $dbh->rollback;
            $webdata{statustext} = "Delete failed!";
            $webdata{statuscolor} = "errortext";
        } else {
            $dbh->commit;
            $webdata{statustext} = "File deleted";
            $webdata{statuscolor} = "oktext";
        }
    }
    
    my @files;
    my $sth = $dbh->prepare_cached("SELECT id, username, created, updated,
                                   filename, is_public
                                   FROM documents
                                   WHERE doctype = 'Word'
                                   AND (is_public = 'true'
                                        OR username = ?)
                                   ORDER BY created DESC")
                or croak($dbh->errstr);
    if(!$sth->execute($webdata{userData}->{user})) {
        $dbh->rollback;
        $webdata{statustext} = "Failed to list the files!?!";
        $webdata{statuscolor} = "errortext";
    } else {
        while((my $line = $sth->fetchrow_hashref)) {
            $line->{updated} = fixDateField($line->{updated});
            $line->{created} = fixDateField($line->{created});
            push @files, $line;
        }
        $sth->finish;
        $dbh->rollback;
    }
    $webdata{Files} = \@files;

    my $template = $self->{server}->{modules}->{templates}->get("docswordprocessor_list", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);

}


sub edit {
    my ($self, $cgi, $mode, $filename, $fileid) = @_;

    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my %webdata = (
        $self->{server}->get_defaultwebdata(),
        PageTitle   =>  $self->{open}->{pagetitle},
        PostLink    =>  $self->{open}->{webpath},
    );

    if(!defined($mode) || !defined($filename)) {
        $mode = $cgi->param("mode") || "edit";
        $filename = $cgi->param("filename") || "";
        $fileid = $cgi->param("fileid") || "";
    }
    if(!defined($fileid)) {
        $fileid = "";
    }
    
    my $webpath = $cgi->path_info();
    if($webpath =~ /\/([0-9]+)$/) {
        $fileid = $1;
        # Call from Search
        # Just fake the call from "view"
        $mode="edit";
    }
    
    my ($nextmode, $data);
    
    # "saveuserform is currently not implemented, turn it to "viewuserform" instead
    # to just reload the form
    # FIXME!
    if($mode eq "saveuserform") {
        $mode = "viewuserform";
    }
    
    # normal mode handling resumes here
    given($mode) {
        when('create') {
            $nextmode = "savenew";
            $fileid = "";
            $data = "";
        }
        when(/^(?:edit|viewuserform)/) {
            if($mode eq "edit") {
                $nextmode = "save";
            } else {
                $nextmode = "saveuserform";
            }
            my $getsth = $dbh->prepare_cached("SELECT content
                                              FROM documents
                                              WHERE id = ?")
                    or croak($dbh->errstr);
            if(!$getsth->execute($fileid)) {
                $dbh->rollback;
                $webdata{statustext} = "Failed to read the files!";
                $webdata{statuscolor} = "errortext";
            } else {
                ($data) = $getsth->fetchrow_array;
                $getsth->finish;
                $dbh->rollback;
            }
        }
        when('savenew') {
            $nextmode = "save";
            $data = $cgi->param("fck1") || "";

            # FIXME: HTML::FormatText is broken
            #my $plain_text = HTML::FormatText->new->format(parse_html($data));
            my $plain_text = $data;

            my $idsth = $dbh->prepare_cached("SELECT nextval('documents_id_seq')")
                    or croak($dbh->errstr);
            my $insth = $dbh->prepare_cached("INSERT INTO documents
                                              (id, username, filename, content, txtcontent, doctype)
                                              VALUES (?, ?, ?, ?, ?, 'Word')")
                    or croak($dbh->errstr);
            if(!$idsth->execute()) {
                $dbh->rollback;
                $webdata{statustext} = "Failed to generate unique ID!";
                $webdata{statuscolor} = "errortext";
            } else {
                ($fileid) = $idsth->fetchrow_array;
                $idsth->finish;
                
                if(!$insth->execute($fileid, $webdata{userData}->{user},
                                    $filename, $data, $plain_text)) {
                    $dbh->rollback;
                    $webdata{statustext} = "Failed to insert file!";
                    $webdata{statuscolor} = "errortext";
                } else {
                    $webdata{statustext} = "File created!";
                    $webdata{statuscolor} = "oktext";
                    $dbh->commit;
                }    
            }
        }
        when('save') {
            $nextmode = "save";
            $data = $cgi->param("fck1") || "";

            # FIXME: HTML::FormatText is broken
            #my $plain_text = HTML::FormatText->new->format(parse_html($data));
            my $plain_text = $data;

            my $upsth = $dbh->prepare_cached("UPDATE documents
                                              SET updated = now(),
                                              content = ?,
                                              txtcontent = ?
                                              WHERE id = ?")
                    or croak($dbh->errstr);
            if(!$upsth->execute($data, $plain_text, $fileid)) {
                $dbh->rollback;
                $webdata{statustext} = "Failed to write the files!";
                $webdata{statuscolor} = "errortext";
            } else {
                $webdata{statustext} = "File saved!";
                $webdata{statuscolor} = "oktext";
                $dbh->commit;
            }
        }
    }
    
    $webdata{FileID} = $fileid;
    $webdata{FileName} = $filename;
    $webdata{FileData} = $data;
    $webdata{EditMode} = $nextmode;
    
    my $templname = "docswordprocessor_edit";
    if($nextmode eq "saveuserform") {
        $templname = "docswordprocessor_view";
    }
    
    my $template = $self->{server}->{modules}->{templates}->get($templname, 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}

1;
__END__

=head1 NAME

Maplat::Web::DocsWordProcessor - edit rich text documents

=head1 SYNOPSIS

This module provides a full Rich Text Editor, complete with embedded links, graphics, forms
and much, much more.

Of course, full text search is available through DocsSearch.

=head1 DESCRIPTION

With the fantastic FCKEditor, this module provides a rich (pun intented) expirience editing
rich text documents. You can use more or less every feature HTML+CSS can offer. It's also
possible to view and edit the HTML source code directly.

Full-text search is provided by DocsSearch.

=head1 Configuration

        <module>
                <modname>docswordprocessor</modname>
                <pm>DocsWordProcessor</pm>
                <options>
                        <list>
                                <pagetitle>WordProcessor</pagetitle>
                                <webpath>/devtest/word/list</webpath>
                        </list>
                        <open>
                                <pagetitle>WordProcessor</pagetitle>
                                <webpath>/devtest/word/open</webpath>
                        </open>
                        <db>maindb</db>
                        <memcache>memcache</memcache>
                        <session>sessionsettings</session>
                </options>
        </module>

=head2 edit

Webform for a single text document.

=head2 list

"File" browser for all text documents.

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
Maplat::Web::DocsSearch
Maplat::Web::DocsSpreadSheet

For more information about FCKEditor, visit http://ckeditor.com/

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

This module uses code and javascripts from http://ckeditor.com/

If you like the word processor, check out if you can support the project by using the above URL.

=cut

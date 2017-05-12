# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::DocsSpreadSheet;
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
use MIME::Base64;

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
    
    # "edit" is not linked directly, it is called via "list"
    #$self->register_webpath($self->{open}->{webpath}, "edit");
    
    $self->register_webpath($self->{list}->{webpath}, "list");
    $self->register_webpath($self->{ajaxget}, "ajaxget");
    $self->register_webpath($self->{ajaxpost}, "ajaxpost");
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

    my $webpath = $cgi->path_info();
    if($webpath =~ /\/([0-9]+)$/) {
        $fileid = $1;
        # Call from Search
        # FIXME: We just fake the filename at this point...
        return $self->edit($cgi, $fileid, "Search result...");
    }

    if(($mode eq "edit" || $mode eq "create" || $mode eq "update" || $mode eq "delete")
            && $filename eq "") {
        $mode = "view";
        $webdata{statustext} = "Need a Filename!";
        $webdata{statuscolor} = "errortext";
    }

    if(($mode eq "edit" || $mode eq "update" || $mode eq "delete")
            && $fileid eq "") {
        $mode = "view";
        $webdata{statustext} = "Internal error: No file id!";
        $webdata{statuscolor} = "errortext";
    }
    
    given($mode) {
        when('edit') {
            return $self->edit($cgi, $fileid, $filename);
        }
        when('create') {
            return $self->edit($cgi, "new", $filename);
        }
        when('update') {
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
        }
        when('delete') {
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
    }
    
    my @files;
    my $sth = $dbh->prepare_cached("SELECT id, username, created, updated,
                                   filename, is_public
                                   FROM documents
                                   WHERE doctype = 'Spreadsheet'
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

    my $template = $self->{server}->{modules}->{templates}->get("docsspreadsheet_list", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);

}


sub edit {
    my ($self, $cgi, $fileid, $filename) = @_;

    # if it's a new file, get the next fileid from the sequence
    # and remember the filename in our session handler:
    # We don't want to create the file right away, we
    # wait until the user saves it the first time. And
    # we only set the gethandler if its an existing file
    my $gethandler;
    if($fileid eq "new") {
        my $dbh = $self->{server}->{modules}->{$self->{db}};
        my $sesh = $self->{server}->{modules}->{$self->{session}};
        
        my $idsth = $dbh->prepare_cached("SELECT nextval('documents_id_seq')")
                or croak($dbh->errstr);
        if(!$idsth->execute()) {
            $dbh->rollback;
            #$webdata{statustext} = "Failed to generate unique ID!";
            #$webdata{statuscolor} = "errortext";
        } else {
            ($fileid) = $idsth->fetchrow_array;
            $idsth->finish;
            $sesh->set("DocSpreadSheet::$fileid", $filename);
        }
    } else {
        $gethandler = $self->{ajaxget} . "/" . $fileid;
    }
    
    my %webdata = (
        $self->{server}->get_defaultwebdata(),
        PageTitle   =>  $self->{list}->{pagetitle},
        AjaxPost    =>  $self->{ajaxpost} . "/" . $fileid,
        AjaxGet        =>  $gethandler,
        FileName    =>  $filename,
    );
    
    my $template = $self->{server}->{modules}->{templates}->get("docsspreadsheet_edit", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}

sub ajaxpost {
    my ($self, $cgi) = @_;
    my $webpath = $cgi->path_info();

    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $sesh = $self->{server}->{modules}->{$self->{session}};

    # We only need webdata to get to the username 8-)
    my %webdata = (
        $self->{server}->get_defaultwebdata(),
        );
    
    my $fileid;
    if($webpath !~ /\/([0-9]+)$/) {
        return (status  =>  404); # ups no fileid
    } else {
        $fileid = $1;
    }

    my $data = $cgi->param("POSTDATA");
    return (status  =>  404) if(!defined($data) || $data eq "");
    
    # Remove some prefix junk from Javascript
    $data =~ s/^s\=//o;

    # FIXME: HTML::FormatText is broken
    #my $plain_text = HTML::FormatText->new->format(parse_html($data));
    my $plain_text = $data;

    # Check if we have a sessiondata entry: If so, make a new
    # file and delete the entry
    my $returnstatus = "INTERNAL ERROR: UNKNOWN STATUS";
    my ($ok, $filename) = $sesh->get("DocSpreadSheet::$fileid");
    if($ok) {
        my $insth = $dbh->prepare_cached("INSERT INTO documents
                                  (id, username, filename, content, txtcontent, doctype)
                                  VALUES (?, ?, ?, ?, ?, 'Spreadsheet')")
        or croak($dbh->errstr);
        
        if(!$insth->execute($fileid, $webdata{userData}->{user},
                            $filename, $data, $plain_text)) {
            $dbh->rollback;
            $returnstatus = "Failed to create document!";
        } else {
            $dbh->commit;
            $returnstatus = "File created.";
            $sesh->delete("DocSpreadSheet::$fileid");
        }
    } else {
        my $upsth = $dbh->prepare_cached("UPDATE documents
                                          SET updated = now(),
                                          content = ?,
                                          txtcontent = ?
                                          WHERE id = ?")
                or croak($dbh->errstr);
        if(!$upsth->execute($data, $plain_text, $fileid)) {
            $dbh->rollback;
            $returnstatus = "File update failed!"
        } else {
            $returnstatus = "File updated.";
            $dbh->commit;
        }
    }

    return (status  =>  200,
            type    => "text/html",
            data    => $returnstatus);
}

sub ajaxget {
    my ($self, $cgi) = @_;
    my $webpath = $cgi->path_info();

    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $sesh = $self->{server}->{modules}->{$self->{session}};

    # We only need webdata to get to the username 8-)
    my %webdata = (
        $self->{server}->get_defaultwebdata(),
        );
    
    my $fileid;
    if($webpath !~ /\/([0-9]+)$/) {
        return (status  =>  404); # ups no fileid
    } else {
        $fileid = $1;
    }

    my $data;
    my $getsth = $dbh->prepare_cached("SELECT content
                                      FROM documents
                                      WHERE id = ?")
            or croak($dbh->errstr);
    if(!$getsth->execute($fileid)) {
        $dbh->rollback;
        return (status  =>  404);
    } else {
        ($data) = $getsth->fetchrow_array;
        $getsth->finish;
        $dbh->rollback;
    }

#    open(my $fh, "<", "/home/cavac/src/maplat/Maplat::Web/Static/jquery.sheet-0.53/charts.html") or croak($!);
#    $data =  join("", <$fh>);
#    close $fh;

    return (status  =>  200,
            type    => "text/html",
            data    => $data);
}

1;
__END__

=head1 NAME

Maplat::Web::DocsSpreadSheet - edit spreadsheets complete with graphs

=head1 SYNOPSIS

This module provides a full SpreadSheet, complete with graphs and charts. The module uses
the fantastic jquery.sheet() module for all visualization and editing.

Of course, full text search is available through DocsSearch.

=head1 DESCRIPTION

With the fantastic jquery plugin jQuery.sheet(), this module provides a full-fledged Spreadsheet,
complete with formulas, charts and graphs. Most of the actions are done through AJAX.

Full-text search is provided by DocsSearch.

=head1 Configuration

        <module>
                <modname>docsspreadsheet</modname>
                <pm>DocsSpreadSheet</pm>
                <options>
                        <list>
                                <pagetitle>SpreadSheet</pagetitle>
                                <webpath>/devtest/spread/list</webpath>
                        </list>
                        <ajaxget>/dev/word/get</ajaxget>
                        <ajaxpost>/dev/word/post</ajaxpost>
                        <db>maindb</db>
                        <memcache>memcache</memcache>
                        <session>sessionsettings</session>
                </options>
        </module>

=head2 edit

Webform for a single Spreadsheet.

=head2 list

"File" browser for all Spreadsheets.

=head2 ajaxget

Internal function.

=head2 ajaxpost

Internal function.

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
Maplat::Web::DocsWordProcessor

For more information about jQuery.sheet(), visit http://jqueryplugins.weebly.com/jquerysheet.html

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

This module uses code and javascripts from http://jqueryplugins.weebly.com/jquerysheet.html

If you like the spreadsheet, please go the jquerysheet homepage and donate a few bucks.

=cut

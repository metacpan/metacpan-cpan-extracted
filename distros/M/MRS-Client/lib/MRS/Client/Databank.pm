#-----------------------------------------------------------------
# MRS::Client::Databank
# Authors: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see MRS::Client pod.
#
# ABSTRACT: Representation of a MRS databank - on a client side
# PODNAME: MRS::Client
#-----------------------------------------------------------------
use warnings;
use strict;
package MRS::Client::Databank;

our $VERSION = '1.0.1'; # VERSION

use Carp;
use MRS::Constants;
use Data::Dumper;

#-----------------------------------------------------------------
# Mandatory argument is an 'id' defining what databank should be
# created. However, this method does not need to be called directly:
# better to use factory method db() of MRS::Client.
# -----------------------------------------------------------------
sub new {
    my ($class, %args) = @_;

    # create an object and fill it from $args
    my $self = bless {}, ref ($class) || $class;
    foreach my $key (keys %args) {
        $self->{$key} = $args {$key};
    }

    # check that we have at least an ID
    croak ("The MRS::Client::Databank instance cannot be created without an ID.\n")
        unless $self->{id};

    # done
    return $self;
}

#-----------------------------------------------------------------
# Getter. Most of them first fill the databank from the server.
# -----------------------------------------------------------------
sub id        { return shift->{id}; }
sub name      { return shift->_populate_info->{name}; }
sub blastable { return shift->_populate_info->{blastable}; }
sub url       { return shift->_populate_info->{url}; }
sub parser    {
    my $self = shift;
    if ($self->{client}->is_v6) {
        return $self->_populate_info->{parser};
    } else {
        return $self->_populate_info->{script};
    }
}
sub files     { return shift->_populate_info->{files}; }
sub indices   { return shift->_populate_indices->{indices}; }
sub count     { return shift->_populate_count->{count}; }

sub version {
    my $self = shift;
    if ($self->{client}->is_v6) {
        return $self->_populate_info->{version};
    } else {
        my $r = '';
        if ($self->files) {
            foreach my $file (@{ $self->files }) {
                $r .= ', ' if $r;
                $r .= $file->version;
            }
        }
        return $r;
    }
}

# returns a meaningful result (an arrayref) only from MRS 6 and above
sub aliases     { return shift->_populate_info->{aliases}; }

#-----------------------------------------------------------------
# Mostly for debugging - because it may be expensive: It calls several
# SOAP operations to fill first the databank.
# -----------------------------------------------------------------
use overload q("") => "as_string";
sub as_string {
    my $self = shift;
    $self->_populate_info();
    my $r = '';
    $r .= "Id:      " . $self->{id}   . "\n";
    $r .= "Name:    " . $self->name . "\n" if $self->{name};
    $r .= "Version: " . $self->version  . "\n";
    $r .= "Count:   " . $self->count  . "\n";
    $r .= "URL:     " . $self->{url}  . "\n" if $self->{url};
    $r .= "Parser:  " . $self->parser  . "\n" if $self->parser;
    $r .= "blastable\n" if $self->{blastable};
    $r .= "Aliases: " . join (", ", @{ $self->aliases } ) . "\n" if $self->aliases;
    $r .= "Files:\n\t" . join ("\n\t", map { my $file = $_; $file =~ s/\n/\n\t/g; $file } @{ $self->files } ) . "\n";
    $r .= "Indices:\n\t" . join ("\n\t", @{ $self->indices } ) . "\n";
    return $r;
}

#-----------------------------------------------------------------
# If this instance does not have yet info data then populate them.
# Return itself (the databank instance).
#-----------------------------------------------------------------
sub _populate_info {
    my $self = shift;
    return $self if $self->{info_processed};

    # it may already be retrieved by the client->db() method for 'all'
    unless ($self->{info_retrieved}) {
        $self->{client}->_create_proxy ('search');
        my $answer = $self->{client}->_call (
            $self->{client}->{search_proxy}, 'GetDatabankInfo',
            { db => $self->{id} });
        if (defined $answer) {
            my $is_alias = ( @{ $answer->{parameters}->{info} } > 1 );
            my $entries = 0;
            my $rawDataSize = 0;
            my $fileSize = 0;
            foreach my $info (@{ $answer->{parameters}->{info} }) {
                foreach my $key (keys %$info) {
                    if ($key eq 'indices') {
                        # special dealing with indices
                        $self->{indices} = [] unless exists $self->{indices};
                        foreach my $ind (@{ $info->{$key} }) {
                            push (@{ $self->{indices} }, MRS::Client::Databank::Index->new (%$ind, db => $info->{id}));
                        }
                        next;
                    }
                    if ($is_alias) {
                        # deal with numeric fields
                        if ($key eq 'entries') {
                            $entries += $info->{$key};
                        } elsif ($key eq 'rawDataSize') {
                            $rawDataSize += $info->{$key};
                        } elsif ($key eq 'fileSize') {
                            $fileSize += $info->{$key};

                        } elsif ($key eq 'aliases' or $key eq 'id') {
                            # ...and ignore aliases and ID when dealing with an alias

                        } else {
                            # ...and concatenate those string fields that are differnt
                            if (exists $self->{$key} and $self->{$key} ne $info->{$key}) {
                                $self->{$key} .= ", $info->{$key}";
                            } else {
                                $self->{$key} = $info->{$key};
                            }
                        }

                    } else {
                        # this databank is NOT an alias
                        $self->{$key} = $info->{$key};
                    }
                }
            }
            if ($is_alias) {
                $self->{entries} = $entries;
                $self->{rawDataSize} = $rawDataSize;
                $self->{fileSize} = $fileSize;
            }
        }
        $self->{info_retrieved} = 1;
    }

    # special treatment for 'files': create File objects
    if ($self->{client}->is_v6) {
        my $file = {};
        $file->{rawDataSize} = $self->{rawDataSize} if defined $self->{rawDataSize};
        $file->{modificationDate} = $self->{modificationDate} if defined $self->{modificationDate};
        $file->{fileSize} = $self->{fileSize} if defined $self->{fileSize};
        $file->{entries} = $self->{entries} if defined $self->{entries};
        $file->{version} = $self->{version} if defined $self->{version};
        $file->{uuid} = $self->{uuid} if defined $self->{uuid};

        $self->{files} = [$file];
    }
    $self->{files} =
        [ map { MRS::Client::Databank::File->new (%$_) } @{ $self->{files} } ];

    $self->{info_processed} = 1;
    return $self;
}

#-----------------------------------------------------------------
# If this instance does not have yet indices then populate them.
# Return itself (the databank instance).
#-----------------------------------------------------------------
sub _populate_indices {
    my $self = shift;
    return $self if $self->{indices_retrieved};

    if ($self->{client}->is_v6) {
        $self->_populate_info();
    } else {
        $self->{client}->_create_proxy ('search');
        my $answer = $self->{client}->_call (
            $self->{client}->{search_proxy}, 'GetIndices',
            { db => $self->{id} });
        $self->{indices_retrieved} = 1;
        if (defined $answer) {
            $self->{indices} =
                [ map { MRS::Client::Databank::Index->new (%$_, db => $self->id) }
                  @{ $answer->{parameters}->{indices} } ];
        }
    }
    return $self;
}

#-----------------------------------------------------------------
# If this instance does not have yet its count then populate it.
# Return itself (the databank instance).
#-----------------------------------------------------------------
sub _populate_count {
    my $self = shift;
    return $self if defined $self->{count};

    if (defined $self->{entries}) {
        $self->{count} = $self->{entries};
        return $self;
    }

    if ($self->{client}->is_v6) {
        $self->_populate_info();
        $self->{count} = $self->{entries};
    } else {
        $self->{client}->_create_proxy ('search');
        my $answer = $self->{client}->_call (
            $self->{client}->{search_proxy}, 'Count',
            { db => $self->{id},
              booleanquery => '*'});
        # print Dumper ($answer);
        if (defined $answer) {
            $self->{count} = $answer->{parameters}->{response};
        } else {
            $self->{count} = 0;
        }
    }
    return $self;
}

#-----------------------------------------------------------------
# Make a query. See MRS::Client::Find->new about the parameters.
#-----------------------------------------------------------------
sub find {
    my $self = shift;

    my $find = MRS::Client::Find->new ($self->{client}, @_);
    $find->{db} = $self->{id};
    $find->{dbobj} = $self;

    my $record = $find->_read_next_hits;
    unshift (@{ $find->{hits} }, $record) if $record;

    return $find;
}

#-----------------------------------------------------------------
# Get an entry defined by $entry_id in the $format (optional). Some
# formats may have extended options in $xformat.
# -----------------------------------------------------------------
sub entry {
    my ($self, $entry_id, $format, $xformat) = @_;

    croak "Empty entry ID. Cannot do anything, I am afraid.\n"
        unless $entry_id;
    $format = MRS::EntryFormat->PLAIN
        unless MRS::EntryFormat->check ($format, $self->{client});
    warn ("Method 'entry' does not support format HEADER. Reversed to TITLE.\n")
        and $format = MRS::EntryFormat->TITLE
        if $format eq MRS::EntryFormat->HEADER;

    $self->{client}->_create_proxy ('search');
    my $answer = $self->{client}->_call (
        $self->{client}->{search_proxy}, 'GetEntry',
        { db => $self->{id},
          id => $entry_id,
          format => $format });
    return '' unless defined $answer;
    if ($xformat and $format eq MRS::EntryFormat->HTML) {
        return $self->_xformat ($xformat, $answer->{parameters}->{entry});
    } else {
        return $answer->{parameters}->{entry};
    }
}

#
sub _xformat {
    my ($self, $xformat, $html) = @_;

    # in these case, the returned content will be different from the given $html
    my $change_wanted = ( $xformat->{MRS::XFormat::CSS_CLASS()}    or
                          $xformat->{MRS::XFormat::REMOVE_DEAD()}  or
                          $xformat->{MRS::XFormat::URL_PREFIX} );

    # in this case, we need a list of available databanks
    # (which may be already provided in $xformat itself)
    if ($xformat->{MRS::XFormat::REMOVE_DEAD()}) {
        if (ref ($xformat->{MRS::XFormat::REMOVE_DEAD()}) ne 'ARRAY' ) {
            $xformat->{MRS::XFormat::REMOVE_DEAD()} = [map { $_->id } $self->{client}->db];
        }
        # internally, change it to a hashref
        $xformat->{'_dbs_'} = { map { $_ => 1 } @{ $xformat->{MRS::XFormat::REMOVE_DEAD()} } };
    }

    my $regex = '(<a (?:.+?)</a>)';
    if ($xformat->{MRS::XFormat::ONLY_LINKS()}) {
        my @links = ( $html =~ m{$regex}migo );
        if ($change_wanted) {
            return [ map { $self->_change_link ($xformat, $_) } @links ];
        } else {
            return \@links
        }
    } else {
        $html =~ s{$regex}{$self->_change_link ($xformat, $1)}emigo;
        return $html;
    }
}

#
sub _change_link {
    my ($self, $xformat, $link) = @_;
    if (my $class = $xformat->{css_class}) {
        $link =~ s/(<a )/$1class="$class" /oi;
    }
    if ($xformat->{url_prefix}) {
        $link =~ s{(href=")(query|entry)}{$1$xformat->{url_prefix}$2}oi;
    }
    if ($xformat->{remove_dead_links}) {
        my ($db) = $link =~ m{[.]do[?]db=(\w+?)&amp;}o;
        if ($db and not $xformat->{'_dbs_'}->{$db}) {
            $link =~ s{<[^>]*>}{}g;
        }
    }
    return $link;
}

#-----------------------------------------------------------------
#
#  MRS::Client::Databank::File ... info about a file of a databank
#
#-----------------------------------------------------------------
package MRS::Client::Databank::File;

our $VERSION = '1.0.1'; # VERSION

sub new {
    my ($class, %file) = @_;

    # create an object and fill it from $file
    my $self = bless {}, ref ($class) || $class;
    foreach my $key (keys %file) {
        $self->{$key} = $file {$key};
    }

    # done
    return $self;
}

sub id             { return shift->{uuid}; }
sub raw_data_size  { return shift->{rawDataSize}; }
sub entries_count  { return shift->{entries}; }
sub file_size      { return shift->{fileSize}; }
sub version        { return shift->{version}; }
sub last_modified  { return shift->{modificationDate}; }

use overload q("") => "as_string";
sub as_string {
    my $self = shift;
    "Version:       " . $self->version       . "\n" .
    "Modified:      " . $self->last_modified . "\n" .
    "Entries count: " . $self->entries_count . "\n" .
    "Raw data size: " . $self->raw_data_size . "\n" .
    "File size:     " . $self->file_size     . "\n" .
    "Unique Id:     " . $self->id
    ;
}

#-----------------------------------------------------------------
#
#  MRS::Client::Databank::Index
#
#-----------------------------------------------------------------
package MRS::Client::Databank::Index;

our $VERSION = '1.0.1'; # VERSION

sub new {
    my ($class, %args) = @_;

    # create an object and fill it from $args
    my $self = bless {}, ref ($class) || $class;
    foreach my $key (keys %args) {
        $self->{$key} = $args {$key};
    }

    # done
    return $self;
}

sub db          { return (shift->{db} or ''); }
sub id          { return shift->{id}; }
sub description { return shift->{description}; }
sub count       { return shift->{count} }
sub type        { return shift->{type}; }

use overload q("") => "as_string";
sub as_string {
    my $self = shift;
    return sprintf (
        "%-15s%-15s%9d  %-9s %s",
        $self->db, $self->id, $self->count, $self->type, $self->description);
}

1;


=pod

=head1 NAME

MRS::Client - Representation of a MRS databank - on a client side

=head1 VERSION

version 1.0.1

=head1 NAME

MRS::Client::Databank - part of a SOAP-based client accessing MRS databases

=head1 REDIRECT

For the full documentation of the project see please:

   perldoc MRS::Client

=head1 AUTHOR

Martin Senger <martin.senger@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Martin Senger, CBRC - KAUST (Computational Biology Research Center - King Abdullah University of Science and Technology) All Rights Reserved..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


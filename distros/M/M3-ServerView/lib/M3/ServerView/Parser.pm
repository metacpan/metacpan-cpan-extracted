package M3::ServerView::Parser;

use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(looks_like_number);
use URI;
use Time::Local qw(timelocal);

use base qw(HTML::Parser);
    
{
    my %Parser;

    sub new {
        my ($pkg, $view) = @_;
        
        my $view_pkg = ref $view || $view;
        _setup_parser_for_view($view_pkg) unless exists $Parser{$view_pkg};
        
        my $self = $pkg->SUPER::new(api_version => 3);
        $self->handler(start    => "_enter_tag", "self, tagname, attr");
        $self->handler(end      => "_leave_tag", "self, tagname");
        $self->handler(text     => "_text", "self, text");
        $self->unbroken_text(1);
        $self->report_tags(qw(table tr td th a));

        $self->{target_view} = $view;
        $self->{target_view_pkg} = $view_pkg;
            
        return $self;
    }
    
    sub _setup_parser_for_view {
        my ($view_pkg) = @_;
        
        my %desc;
        $desc{column_name} = {};
        $desc{column_id} = {};
        $desc{column_setter} = {};
        
        $desc{entry_class} = $view_pkg->_entry_class;
        
        my $i = 1;
        my @columns = $view_pkg->_entry_columns;
        while (my ($column, $desc) = splice @columns, 0, 2) {
            $column = lc $column;
            $desc{column_name}->{$i} = $column;
            $desc{column_id}->{$column} = $i;
            
            my $setter;
            
            if (ref $desc eq "ARRAY") {
                my ($key, $type) = @$desc;
                if ($type eq "text") {
                    $setter = sub {
                        my ($view, $entry, $value) = @_;
                        $entry->{$key} = $value;
                    }
                }
                elsif ($type eq "numeric") {
                    $setter = sub {
                        my ($view, $entry, $value) = @_;
                        if (looks_like_number($value)) {
                            $entry->{$key} = $value;
                        }
                        else {
                            $entry->{$key} = undef;
                        }
                    }
                }
                elsif ($type eq "datetime") {
                    $setter = sub {
                        my ($view, $entry, $value) = @_;
                        if ($value =~ /^ (\d\d\d\d)(\d\d)(\d\d) - (\d\d) : (\d\d) : (\d\d) $/x) {
                            $entry->{$key} = timelocal($6, $5, $4, $3, $2 - 1, $1);
                        }
                    }
                }
                else {
                    croak "Unkown type '$type'";
                }
            }
            elsif (ref $desc eq "CODE") {
                $setter = $desc;
            }
            else {
                croak "Unkown column handler type for '${column}'";
            }
            
            $desc{column_setter}->{$i++} = $setter;
        }
        
        $desc{column_count} = $i - 1;
        
        $Parser{$view_pkg} = \%desc;
    }
    
    sub _has_column_named {
        my ($self, $name) = @_;
        my $view_pkg = $self->{target_view_pkg};
        return $Parser{$view_pkg}->{column_id}->{$name};
    }
    
    sub _column_id {
        my ($self, $name) = @_;
        return $Parser{$self->{target_view_pkg}}->{column_id}->{$name};
    }
    
    sub _column_setter {
        my ($self, $id) = @_;
        return $Parser{$self->{target_view_pkg}}->{column_setter}->{$id};
    }
    
    sub _entry_class {
        my ($self) = @_;
        return $Parser{$self->{target_view_pkg}}->{entry_class};
    }
}

sub parse {
    my ($self, $document) = @_;

    # Clean object
    delete @{$self}{qw(in_table row table_is_data column in_table_cell in_table_row)};
    $self->SUPER::parse($document);
    if ($self->{current_entry}) {
        $self->{target_view}->_add_entry(delete $self->{current_entry});
    }
}

sub _enter_tag {
    my ($self, $tagname, $attr) = @_;
    
    if ($tagname eq "table") {
        $self->{in_table} = 1;
        $self->{row} = 0;
        $self->{table_is_data} = 1;
        
        # Some pages don't send a initial tr
        $self->{_handle_corrupt_open_row} = 1;
    }
    elsif ($tagname eq "tr" && $self->{in_table}) {
        delete $self->{_handle_corrupt_open_row};
        
        $self->{in_table_row} = 1;
        $self->{row}++;
        $self->{column} = 0;
        
        if ($self->{current_entry}) {
            $self->{target_view}->_add_entry(delete $self->{current_entry});
        }

        if ($self->{row} > 1 && $self->{table_is_data}) {
            # We expect to be data
            my $entry = $self->_entry_class->new;
            $self->{current_entry} = $entry;
        }
    }
    elsif (($tagname eq "td" || $tagname eq "th") && ($self->{in_table_row} || $self->{_handle_corrupt_open_row})) {
        if ($self->{_handle_corrupt_open_row}) {
            $self->{in_table_row} = 1;
            $self->{row}++;
            $self->{column} = 0;
        }
        
        $self->{column}++;
        $self->{in_table_cell} = 1;
    }
    elsif ($tagname eq "a" && $self->{in_table_cell} && $self->{table_is_data} && $self->{row} > 1 && $self->{current_entry}) {
        my $href = $attr->{href};
        if ($href) {
            my $setter = $self->_column_setter($self->{column});
            if ($setter) {
                $setter->($self->{target_view}, $self->{current_entry}, URI->new($href));
            }
        }
    }
}

sub _text {
    my ($self, $text) = @_;
    
    if ($self->{in_table_cell}) {
        # Check if this is header
        if ($self->{row} == 1) {
            my ($column) = lc($text) =~ /^\s*(.*?)\s*$/;
            if ($self->_has_column_named($column)) {
                if ($self->_column_id($column) != $self->{column}) {
                    $self->{table_is_data} = 0;
                }
            }
            else {
                $self->{table_is_data} = 0;                
            }
        }
        elsif ($self->{row} > 1 && $self->{current_entry}) {
            # Set key for entry
            my $setter = $self->_column_setter($self->{column});
            if ($setter) {
                $setter->($self->{target_view}, $self->{current_entry}, $text);
            }
        }
    }
}

sub _leave_tag {
    my ($self, $tagname) = @_;

    delete $self->{in_table_cell}   if $tagname =~ /^table|tr|td$/;
    delete $self->{in_table_row}    if $tagname =~ /^table|tr$/;
    delete $self->{in_table}        if $tagname eq "table";
}

1;
__END__

=head1 NAME

M3::ServerView::Parser - Parser for table based views

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item new ( VIEW )

Creats a new parser for parsing contents and put them in the given I<VIEW>. View must 
be a C<M3::ServerView::View>-instance and conform to C<M3::ServerView::...>

=item parse ( HTML )

Parses the HTML and polulates the view if possible.

=back

=cut

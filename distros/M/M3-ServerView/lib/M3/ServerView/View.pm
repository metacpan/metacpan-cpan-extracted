package M3::ServerView::View;

use strict;
use warnings;

use Carp qw(croak);
use POSIX qw(strftime);
use Scalar::Util qw(refaddr looks_like_number);

use M3::ServerView::Parser;
use M3::ServerView::ResultSet;

my %Entries;
my %Connection;
my %Response_time;
my %Request_time;
my %Url;

# Constructor
sub new {
    my ($pkg, $connection, $url) = @_;

    my $self = bless \do { my $v; }, $pkg;

    $Url{refaddr $self} = $url;
    $Connection{refaddr $self} = $connection if $connection;

    $self->reload();
    
    return $self;
}

# Deconstructor
sub DESTROY {
    my ($self) = @_;
    delete $Connection{refaddr $self};
    delete $Entries{refaddr $self};
    delete $Response_time{refaddr $self};
    delete $Request_time{refaddr $self};
    delete $Url{refaddr $self};
}

sub connection {
    my ($self) = @_;
    return $Connection{refaddr $self};
}

# Page loading
sub reload {
    my ($self) = @_;
    $self->_load();
}

sub _load {
    my ($self) = @_;

    # Clear entries
    $Entries{refaddr $self} = [];

    return unless $Url{refaddr $self};
    
    # Fetch page
    $Request_time{refaddr $self} = CORE::time;
    my ($content, $response_time) = $self->connection->_get_page_contents($Url{refaddr $self});
    $Response_time{refaddr $self} = sprintf("%.6f", $response_time);
    
    # Parser contents
    $self->_parse($content);
    
    1;
}

# Generic fallback parser that uses M3::ServerView::Parser;
sub _entry_class {
    my ($self) = @_;
    croak "View class '", ref $self, "' doesn't override _entry_class()";
}

sub _entry_columns {
    my ($self) = @_;
    croak "View class '", ref $self, "' doesn't override _entry_columns()";
}

sub _parse {
    my ($self, $content) = @_;
    my $parser = M3::ServerView::Parser->new($self);
    $parser->parse($content);
}


sub _entries {
    my ($self) = @_;
    return $Entries{refaddr $self};
}

sub _add_entry {
    my ($self, $entry) = @_;
    push @{$Entries{refaddr $self}}, $entry;
}

sub response_time {
    my ($self) = @_;
    return $Response_time{refaddr $self};
}

sub request_time {
    my ($self, $format) = @_;
    my $time = $Request_time{refaddr $self};

    if ($format && $format eq "timestamp") {
        return $time;
    }
    
    return strftime("%Y-%m-%d %H:%M:%S", localtime($time));
}

sub search {
    my ($self, $query, $options) = @_;
    
    $options = {} unless ref $options eq "HASH";
    
    my @matches;
    
    # Build rules
    my $case_sensitive = $options->{case_sensitive};
    $case_sensitive = 0 unless defined $case_sensitive;
    my @matchers = _build_matchers($query, $case_sensitive);
    
    CHECK_ENTRIES: for my $entry (@{$self->_entries}) {
        # Check if entry matches all matchers and 
        # break at the first that doens't
        !($_->($entry)) && next CHECK_ENTRIES for @matchers;
        
        push @matches, $entry;
    }
    
    # Sort results
    if (exists $options->{order_by}) {
        no warnings;
        my $key = $options->{order_by};
        my $sort_as = $options->{sort_as} || "";
        my $sort_order = lc($options->{sort_order}) || "asc";
        croak q{Sort order must be either 'asc' or 'desc'} unless $sort_order =~ /^asc|desc$/;
        if ($sort_order eq "asc") {
            if ($sort_as eq "text") {
                @matches = sort { $a->{$key} cmp $b->{$key} } @matches;
            }
            else {
                @matches = sort { $a->{$key} <=> $b->{$key} } @matches;                
            }
        }
        else {
            if ($sort_as eq "text") {
                @matches = sort { $b->{$key} cmp $a->{$key} } @matches;
            }
            else {
                @matches = sort { $b->{$key} <=> $a->{$key} } @matches;                
            }
        }
    }
    
    my $rs = M3::ServerView::ResultSet->new(\@matches);
    return $rs;
}

my %Op = (
    "=="    => sub { $_[0] == $_[1]; },
    "!="    => sub { $_[0] != $_[1]; },
    "<"     => sub { $_[0] < $_[1]; },
    ">"     => sub { $_[0] > $_[1]; },
    "<="    => sub { $_[0] <= $_[1]; },
    ">="    => sub { $_[0] >= $_[1]; },

    "eq"    => sub { $_[0] eq $_[1]; },
    "ne"    => sub { $_[0] ne $_[1]; },
    "lt"    => sub { $_[0] lt $_[1]; },
    "gt"    => sub { $_[0] gt $_[1]; },
    "le"    => sub { $_[0] le $_[1]; },
    "ge"    => sub { $_[0] ge $_[1]; },
    
    "like"  => sub { $_[0] =~ m{ $_[1] }xi; },
);

my %Op_transform = (
    "=="    => "eq",
    "!="    => "ne",
    ">"     => "gt",
    "<"     => "lt",
    ">="    => "ge",
    "<="    => "le",
);

sub _build_matchers {
    my ($rules, $case_sensitive) = @_;

    $rules = {} unless $rules;
    
    my @matchers;

    while (my ($key, $rule) = each %$rules) {
        my ($op, $value) = ("==", $rule);
        
        if (ref $rule eq "ARRAY") {
            ($op, $value) = @$rule;
        }

        croak "Don't know how to handle op '${op}'" if !exists $Op{$op};
        
        if (!looks_like_number($value) && exists $Op_transform{$op}) {
            $op = $Op_transform{$op};
        }

        my $matcher;
        
        # Basicly the same subroutine except we lowercase the contents if we
        # perform a case-insensitive match
        if ($case_sensitive) {
            $matcher = sub {
                my $entry = shift;
                return 0 unless exists $entry->{$key};
                return 0 unless defined $entry->{$key};
                return 0 unless $Op{$op}->($entry->{$key}, $value);
                return 1;
            };
        }
        else {
            $matcher = sub {
                my $entry = shift;
                return 0 unless exists $entry->{$key};
                return 0 unless defined $entry->{$key};
                return 0 unless $Op{$op}->(lc($entry->{$key}), lc($value));
                return 1;
            };            
        }
        
        push @matchers, $matcher;
    }
    
    return @matchers;
}

1;
__END__

=head1 NAME

M3::ServerView::View - Base class for views

=head1 DESCRIPTION

This class serves as a base class for 'views'. A view is a page in the web-interface which 
contains a set of data we want to be able to access and search.

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item new ( CONNECTION, URL ) 

Creates a new view which maps to given URL.

=back

=head2 INSTANCE METHODS

=over 4

=item connection

Returns the C<M3::ServerView>-instance that was used to retrieve the view with.

=item reload 

Reloads the data for the view from the server.

=item response_time

Returns the number of seconds it took to get the reply from the server.

=item request_time

The date and time in ISO 8601 format when the request was made.

=item search ( [QUERY [, OPTIONS ]] )

Performs a search of the data and returns a L<M3::ServerView::ResultSet|M3::ServerView::ResultSet>-instance.

B<QUERY FORMAT>

If I<QUERY> is specified it must be a hash reference. Each key is a name of an attribute in the entry which must 
exist or the match will fail. The value should either be a scalar which will be compared with the 
entries value for the attribute using either C<==> or C<eq> depending on whether it's numerical or not. More complex 
comparisions can be declared by passing an array reference as value where the first element is an comparison operator 
and the second element the value to compare with. The following comparisions can be defined

C<< == != < > <= >= >> -  Numerical equals, not equals, less than, greater than, 
less or equal than, greater or equal than

C<< eq ne lt gt le ge >> - Same as above but string equivalents

C<like> - Regular expression comparision

Examples 

  # Find all entries who's status is down
  $rs = $view->search({ status => 'down' });
  
  # Find all entries with more than 20 threads and order by threads descending
  $rs = $view->search({ 
    threads => [ '>' => 20] 
  }, { 
    order_by => 'threads', 
    sort_order => 'desc',
  });
  
  # Find all entries whose type begins with "Sub:A"
  $rs = $view->search({ type => [ 'like' => '^Sub:A' ]});

B<OPTIONS>
  
Specifiying options the the search is possible by passing a hash reference. The following options valid:

=over 4

=item case_sensitive = 1 | 0

Sets if comparision should be case_insensitive or not. Defaults to true.

=item order_by = I<attribute>

Sets the name of the attribute to sort by.

=item sort_order = "asc" | "desc"

Sets the order of the search. Defaults to "asc".

=item sort_as = "text" | "numerical"

Sets the if the sort should be considered numerical or not. In numerical mode (1, 55, 7) sortes as (1, 7, 55) while in 
text mode it sorts as (1, 55, 7).

=back

=back

=cut
package File::Version;

use 5.006;
use strict;
use warnings;
use integer;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(); # nothing to export, this is OO 
our $VERSION = '0.02';
use Carp;

# file-private functions

my $recursive_find = sub {
    my $self = shift;
    my $regex = shift;
    my($loc_recursive, $rec_depth, @matches);
    $loc_recursive = sub {
        my $path = shift;
        return if $self->{RECURSION_DEPTH} && (scalar @$path > $rec_depth);
        my $str_path = join('/', @$path);
        substr($str_path, 0, 0) = '/' unless $str_path =~ /^\.+\/?/;
        opendir(PH, $str_path);
        my @files = grep(!/^\.\.?$/, readdir(PH));
#weed out symbolic links unless FOLLOW_SYMBOLIC is true
        @files = grep( !( -l $_ ), @files) unless $self->{FOLLOW_SYMBOLIC}; 
        closedir(PH);
        for(@files) {
            my @temp = @$path;
            push(@temp, $_);
            my $string_loc = join('/', @temp);
            substr($string_loc, 0, 0) = '/' unless $string_loc =~ /^\.+\/?/;
            next unless (-r $string_loc);
            if( -f $string_loc && /$regex/ ) { 
                push(@matches, $string_loc);
            }
            if( -d $string_loc ) { 
               &$loc_recursive(\@temp); 
            }
        }
    };

    for(@ { $self->{SEARCH_PATHS} }) {
       
        my @dir_parts = grep(/./, split '/');
        $rec_depth = ($self->{RECURSION_DEPTH} + scalar @dir_parts); 
        &$loc_recursive([ @dir_parts ]);
    } 
    @matches ? return \@matches : return;
};

# constructor

sub new {
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $self = { SEARCH_PATHS     => [ qw(.) ], # search current directory
                 RECURSION_DEPTH => 0,   
                 FOLLOW_SYMBOLIC => 0, # default: don't follow symlinks  
    };
# validate user supplied arguments
    my %args = @_;
    croak( "Invalid file" ) unless( $args{FILE} && -f $args{FILE} && -r _);
    if($args{FILE} =~ /^(.*\/)?((?:\d+_)+?)(?:0_)*_(.+)$/) {
        $self->{FILE} = $3 or croak( "Invalid file.\n" ); 
        $self->{VERSION} = $2 || '';
    }
    elsif($args{FILE} =~ /^(.*\/)?(.+)$/) {
        $self->{FILE} = $2 or croak( "Invalid file.\n" );
        $self->{VERSION} = '';
    }
    else { croak( "Invalid file" ) };
    $self->{FILE_PATH} = $1 if $1;
    $self->{WHOLE} = $& or croak( "Invalid file.\n" );

    if ( $args{SEARCH_PATHS} && @{ $args{SEARCH_PATHS} }) {
        for(@{ $args{SEARCH_PATHS} }) {
            if( -d && -r) { 
                push @{ $self->{SEARCH_PATHS} }, $_;
            }
            else { 
                carp ( "Directory does not exist: $_\n"); 
            }
        }
    }
    if ($args{RECURSION_DEPTH}) {
        croak ( "Invalid RECURSION_DEPTH: $args{RECURSION_DEPTH}\n")
          unless $args{RECURSION_DEPTH} =~ /^[+]?\d+$/;
        $self->{RECURSION_DEPTH} = $args{RECURSION_DEPTH};
    }
    $self->{FOLLOW_SYMBOLIC} = $args{FOLLOW_SYMBOLIC} ? 1 : 0;
    bless $self, $class;
    return $self;
}

# OO functions

sub recursion_depth {
    my $self = shift;
    if(@_) { $self->{RECURSION_DEPTH} = shift }
    return $self->{RECURSION_DEPTH};
}

sub follow_symbolic {
    my $self = shift;
    my %args = @_;
    $self->{FOLLOW_SYMBOLIC} = $args{FOLLOW_SYMBOLIC} ? 1 : 0;
    return $self->{FOLLOW_SYMBOLIC};
}

sub search_paths {
    my $self = shift;
    my %args = @_;
    if (@{ $args{SEARCH_PATHS} }) {
        for(@{ $args{SEARCH_PATHS} }) {
            if( -d && -r) {
                push @{ $self->{SEARCH_PATHS} }, $_;
            }
            else {
                carp ( "SEARCH_PATHS not set: $_\n");
            }
        }
    }
    else { carp ( "SEARCH_PATHS not set.\n"); }
    return $self->{SEARCH_PATHS};
}

sub locate_ancestors {
    my $self = shift;
    my @gens;
        @gens = split('_', $self->{VERSION});
        my $gen_count = 0;
        while(@gens) {
            my $match;
            my $regex = join('_', @gens) . "_(?:0_)*_$self->{FILE}";
            $regex = eval { qr/$regex/ } || croak "Invalid pattern.\n";
            ($match = &$recursive_find($self, $regex)) && do {
                for(@$match) { $self->{ANCESTORS}{$gen_count}{$_}++; } 
            };
            $gen_count++;
            pop(@gens);
        };
    return $self->{ANCESTORS};
}

sub locate_descendants {
    my $self = shift;
    my $match;
    my $regex = eval { qr/^$self->{VERSION}(?:\d+_)+?(?:0_)*_$self->{FILE}/ }
      || croak "Invalid pattern.\n";
    ($match = &$recursive_find($self, $regex)) && do {
        for(@$match) { 
            if( my($gen) = /$self->{VERSION}((\d+_)+?)(?:0_)*_/) {
                my $count = ($gen =~ tr/\_//);
                (my $last = $+) =~ s/\D//g if $+; 
                $self->{DESCENDANTS}{$count}{$_} = $last || 0; 
            }
        }
    };
    return $self->{DESCENDANTS};
};

sub next_version {
    my $self = shift;
    my $high = 0;
    &locate_descendants($self) unless $self->{DESCENDANTS}; 
    $self->{DESCENDANTS} && do {
        for(keys(% { $self->{DESCENDANTS}{1} } )) {
            $high = $self->{DESCENDANTS}{1}{$_} if $high < $self->{DESCENDANTS}{1}{$_};
        }
    };
    $self->{NEXT_VERSION} = $self->{VERSION} . ++$high . "__$self->{FILE}";
    return $self->{NEXT_VERSION};
}

1;
__END__

=head1 NAME

File::Version.pm - Simple File Versioning Class

=head1 SYNOPSIS

use File::Version;

my %args =
(
    FILE            => 'foo.txt',
    SEARCH_PATHS    => ['/projects'], 
    RECURSION_DEPTH => 10,
    FOLLOW_SYMBOLIC => 0 
);

my $foo = File::Version->new(%args);

=head1 METHODS

=over 2 

=item *

$foo->locate_ancestors;
# recursively search /project 10 directories deep for all 'foo.txt' ancestors

=item *

$foo->locate_descendants;
# recursively search /project 10 directories deep for all 'foo.txt' descendants

=item *

$foo->next_version;
# next version of 'foo.txt'

=item *

$foo->search_paths( SEARCH_PATHS => [ '/home' ] );
# now search all home directories 

=item *

$foo->recursion_depth( RECURSION_DEPTH => 5 );
# now seach only 5 directories deep

=item *

$foo->follow_symbolic( FOLLOW_SYMBOLIC => 1 );
# follow symbolic links (not recommended)

=head1 DESCRIPTION

This module is useful for creating and locating different versions of a file.
For example, let's say you're working with a first generation file named foo.txt.  
Before proceeding, we gather some information about the foo.txt family tree: 

my %args =
(
    FILE            => '/path/foo.txt',
    SEARCH_PATHS    => ['/home'], 
    RECURSION_DEPTH => 10,
    FOLLOW_SYMBOLIC => 0 
);

my $foo = File::Version->new(%args); 

$foo->locate_descendants might return the following reference :

$ref = {
         '1' => {
                  '/home/bill/1__foo.txt' => '1',
                  '/home/mary/foobar/test/2__foo.txt' => '2'
                },
         '2' => {
                  '/home/bill/2_1__foo.txt' => '1',
                  '/home/john/project/2_2__foo.txt' => '2',
                  '/home/fred/mystuff/1_1__foo.txt' => '1'
                },
         '3' => {
                  '/home/jill/2_2_1__foo.txt' => '1'
                }
       };

meaning that foo.txt has :

2 children,
3 grandchildren,
1 great grandchild

$foo->locate_ancestors has the opposite effect, returning undef in this case because foo.txt is an original file.

$foo->next_version returns '3__foo.txt', meaning the third child of foo.txt.  
A file named '3_1__foo.txt' would mean the first child of foo.txt's third child.

=head1 SUGGESTIONS

=over 2

=item *

Use the Algorithm::Diff module to compare different versions. 

=item *

The cp_version.pl script (provided with this module) takes filenames as arguments from the command line and spits out the next version of each file.  
Alias this script for your convenience.

=head1 BUGS

This module was written and tested using Perl 5.6.0 under Linux.  
If you want this module to work with Windows, at minimum you'll need to change the directory separator to a backslash.     
Comments and suggestions welcome.

=head1 AUTHOR

Nathaniel J. Graham E<lt>broom@pincer.orgE<gt>

=head1 COPYRIGHT

Copyright 2003, Nathaniel J. Graham.  All Rights Reserved.
This program is free software.  You may copy or
redistribute it under the same terms as Perl itself.

=cut

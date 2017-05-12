package Hardware::Vhdl::Automake::PreProcessor;

# file line-reader, which can delegate preprocessing to a preprocessor module specified in the first line of the file
# to do:
#  check first line for PreProcessor selector, and attempt to auto-load it and use it

#use AutoLoader;              # don't import AUTOLOAD, define our own
use Carp;
use strict;
use warnings;

our $file_slurp_limit = 16000; # the size of the chunks of file we read at a time

our $VERSION          = "1.00";

=for notes
    For a 'delegate' style preprocessor, the module must provide the following class methods:
        Class->pp_style() - must return the string 'delegate'
        Class->new(sourcefile => $filename, includepaths => [$path1, $path2...], defines => {name1 => 'value1'...} )
    and the following object methods:
        get_next_line() - returns a line and its newline at the end, or the last line (perhaps without a newline) or undef if there are no more lines
        linenum() - returns the line number of the last line fetched
        sourcefile() - returns the source file of the last line fetched
        files_used() - returns a list of all the source files used

    For a 'wholefile_with_synclines' style preprocessor, the module must provide the following class methods:
        Class->pp_style() - must return the string 'wholefile_with_synclines'
        $tempfile = Class->preprocess(sourcefile => $filename, includepaths => [$path1, $path2...], defines => {name1 => 'value1'...} )
            This should preprocess the file and return a filename for the output file, which will be deleted later
=cut

sub new {
    my $class = shift;
    my %args  = @_;
    my $self  = {
            ungot => '',
            line    => '',
            linenum => 0,
            source  => undef,
            endat => undef,
            delegate => undef,
            firstline => 1,
            no_processing => 0,
        };
    
    if ( exists $args{no_processing} && $args{no_processing} ) {
        $self->{no_processing} = 1;
        for my $optname (qw/preprocessor/) {
            croak "argument $optname to $class is not allowed if no_processing option is set" if exists $args{$optname};
        }
    } else {
        for my $optname (qw/sourcestring startat endat linenum/) {
            croak "argument $optname to $class is not allowed unless no_processing option is set" if exists $args{$optname};
        }
    }
    
    if ( defined $args{sourcestring} ) {
        $self->{sourcestring} = $args{sourcestring};
        if (defined $self->{endat}) { $self->{sourcestring} = substr $self->{sourcestring}, 0, $self->{endat} }
        if (defined $self->{startat}) { $self->{sourcestring} = substr $self->{sourcestring}, $self->{startat} }
        $self->{source}       = '<passed string>';
    } elsif ( defined $args{sourcefile} ) {
        my $fhi;
        -f $args{sourcefile} || croak "File '$args{sourcefile}' does not exist\n";
        open $fhi, "<$args{sourcefile}" || croak "Could not read '$args{sourcefile}'\n";
        $self->{fhi} = $fhi;
        binmode $self->{fhi};
        $self->{filebuf}                        = '';
        $self->{source}                         = $args{sourcefile};
        $self->{files_used}{ $args{sourcefile} } = undef;
    } else {
        croak "No source code specified" unless defined $self->{source};
    }
    if (defined $args{startat} && defined $self->{fhi}) { seek $self->{fhi}, $args{startat}, 0 }
    if (defined $args{endat}) { $self->{endat} = $args{endat}; }
    if (defined $args{linenum}) { $self->{linenum} = $args{linenum}-1; }
    bless $self, $class;
    
    $self->_select_preprocessor($args{preprocessor}) if ( defined $args{preprocessor} );

    $self;
}

sub linenum {
    # returns the line number of the last line fetched
    defined $_[0]->{delegate} ? $_[0]->{delegate}->linenum : $_[0]->{linenum};
}

sub sourcefile {
    # returns the source file of the last line fetched
    defined $_[0]->{delegate} ? $_[0]->{delegate}->sourcefile : $_[0]->{source};
}

sub files_used {
    # returns a list of all the source files used
    defined $_[0]->{delegate} ? $_[0]->{delegate}->files_used : $_[0]->{source};
}

sub unget {
    my $self  = shift;
    $self->{ungot} = $_[0] . $self->{ungot};
}

sub get_next_line {
    # returns a line and its newline at the end, or the last line (perhaps without a newline) or undef
    my $self = shift;
    return $self->{delegate}->get_next_line if defined $self->{delegate};

    if ($self->{ungot} ne '') {
        if ( $self->{ungot} =~ m/^(.*?(\015\012?|\012\015?))(.*)$/s ) {
            $self->{line} = $1;
            $self->{ungot} = $3;
        } else {
            $self->{line} = $self->{ungot}."\n";
            $self->{ungot} = '';
        }
    } else {
        $self->_just_get_a_line;
        if ( defined $self->{line} ) {
            $self->{linenum}++;
        }
    }

    # check for preprocessor selection in first line of file
    #~ if ($self->{firstline}) {
        #~ print "First line is $self->{line}\n";
        #~ print "Preprocessing is " . ($self->{no_processing} ? 'disabled' : 'enabled') . "\n";
    #~ }
    if ($self->{firstline} && !$self->{no_processing} && $self->{line} =~ m/ --< \s* use \s+ preprocess[oe]r \s+ (\S+) \s* >-- /xms) {
        my $ppname = $1;
        #~ print "Preprocessor '$ppname' requested\n";
        $self->{firstline} = 0;
        $self->_select_preprocessor($ppname);
        return $self->get_next_line;
    }
    $self->{firstline} = 0;
    
    #print "# got line $self->{linenum}: '$self->{line}'\n";
    wantarray ? ( $self->{line}, $self->{source}, $self->{linenum} ) : $self->{line};
}

sub _select_preprocessor {
    my ($self, $pp) = @_;
    my $ppclass = 'Hardware::Vhdl::Automake::PreProcessor::'.$pp;
    #print "# preprocessor $pp requested!\n";
    my $ppstyle;
    eval "
        require $ppclass;
        #eval { import $ppclass; };
        \$ppstyle = $ppclass->pp_style();
        ";
    die "Could not load preprocessor plugin '$pp':$@\n" if $@;
    
    if ($ppstyle eq 'delegate') {
        $self->{delegate} = $ppclass->new(sourcefile => $self->{source});
        #print "# Delegating to preprocessor plugin '$pp'\n";
    } elsif ($ppstyle eq 'wholefile_with_synclines') {
        my $ppfile;
        eval "\$ppfile = $ppclass->preprocess(sourcefile => \$self->{source});";
        die "Preprocessor plugin '$pp' failed: $@\n" if $@;
        $self->{delegate} = Hardware::Vhdl::Automake::PreProcessor->new(no_processing => 1, sourcefile => $ppfile, delete_source => 1);
    } else {
        die ref($self)." does not recognise preprocessor plugin style '$ppstyle'\n";
    }
}

sub _just_get_a_line {
    my $self  = shift;
    
    $self->{line} = undef;    # default return value
    my $bufname = exists $self->{sourcestring} ? 'sourcestring' : 'filebuf';

    # Just what is used as a newline may vary from OS to OS. Unix traditionally uses \012, one type of DOSish I/O uses \015\012, and Mac OS uses \015.

    GET_LINE: {
        my $rem;
        if (defined $self->{endat}) { $rem = $self->{endat} - tell($self->{fhi}) } # REMainding bytes we are allowed to read from the file
        if ( $self->{$bufname} =~ m/^(.*?(\015\012?|\012\015?))(.*)$/s ) {
            $self->{line}     = $1;
            $self->{$bufname} = $3;
        } elsif ( exists $self->{fhi} && !eof $self->{fhi} && (!defined $rem || ($rem > 0))) {
            local $/ = \$file_slurp_limit;
            if (defined $rem && $file_slurp_limit > $rem) { $/ = \$rem }
            $self->{$bufname} .= readline $self->{fhi};
            redo GET_LINE;
        } else {
            $self->{line}     = $self->{$bufname};
            $self->{$bufname} = '';
        }
    }
    $self->{line} = undef if $self->{line} eq '';
}

1;

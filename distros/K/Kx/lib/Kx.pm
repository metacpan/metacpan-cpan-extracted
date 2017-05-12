package Kx;
$Kx::VERSION = '0.042';
use 5.008;
use strict;
use warnings;
use Carp;
use POSIX ();

my $DEBUG = 0;

my %NULL = (
    'symbol'   => '`',
    'short'    => "0Nh",
    'int'      => "0N",
    'long'     => "0Nj",
    'real'     => "0Ne",
    'float'    => "0n",
    'char'     => " ",
    'month'    => '0Nm',
    'date'     => '0Nd',
    'datetime' => '0Nz',
    'minute'   => '0Nu',
    'second'   => '0Nv',
    'time'     => '0Nt',
);
my %CAST = (
    'symbol'   => '`$"',
    'short'    => '"h"$',
    'int'      => '"i"$',
    'long'     => '"j"$',
    'real'     => '"e"$',
    'float'    => '"f"$',
    'char'     => '"c"$',
    'month'    => '"m"$',
    'date'     => '"d"$',
    'datetime' => '"z"$',
    'minute'   => '"u"$',
    'second'   => '"v"$',
    'time'     => '"t"$',
);

my @TYP = qw/KC KD KE KF KG KH KI KJ KM KS KT KU KV KZ XD XT/;

my %DB = ();    # Place to store class wide connections to KDBs

sub whowasi { ( caller(1) )[3] . '()' }

sub AUTOLOAD {

    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ( $constname = $AUTOLOAD ) =~ s/.*:://;
    croak "&Kx::constant not defined" if $constname eq 'constant';
    my ( $error, $val ) = constant($constname);
    if ($error) { croak $error; }
    {
        no strict 'refs';
        *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load( 'Kx', $Kx::VERSION );

=head1 NAME

Kx - Perl extension for Kdb+ L<http://kx.com>

=head1 SYNOPSIS

    use Kx;

    my $k = Kx->new(host=>'localhost', port=>2222);
    $k->connect() or die "Can't connect to Kdb+ server";

    my $rtn = $k->cmd('til 8');
    my $sum = $k->cmd('{x+y}', $k->int(5)->kval, $k->int(7)->kval);

    my $lst = $k->listof(5, Kx::KI());
    for (0 .. 4) {
        $lst->at($_, $_);
    }
    my $ktyp = Kx::kType($lst->kval);
    my $lst_perl = $lst->val;


=head1 DESCRIPTION

Alpha code.
Create a wrapper around Kdb+ and Q in Perl using the C interface to Kdb+

=head1 EXPORT

None by default.

=head1 METHODS

=cut

=head2 New

    my $k = Kx->new(name=>'local22', host=>'localhost', port=>2222);

Create a new Kx object. Set the connection paramaters to conect to 'host'
and 'port' as specified.

No connection is made to the server until you call $k->connect()

If you don't define a name it defaults to 'default'. Each subsequent call
to new() will use the same 'default' connection.

So once you make a connection later calls to new() with the same name
will use the same connection without further connect() calls required.

    my $k = Kx->new(host=>'localhost', port=>2222);
    $k->connect() or die "Can't connect to Kdb+ server";

    # picks up previous default connection to localhost port 2222 and
    # will use it as well.
    my $k1 = Kx->new();

Also username and passwords are supported. Just add the userpass
attribute thus:

    $k = Kx->new(name=>'local22', 
                 host=>'localhost', 
                 port=>2222,
                 userpass=>'user:pass');

=cut

# we use %DB to hold all our connection details.
sub new {
    my $self  = shift;
    my %opts  = @_;
    my $class = ref($self) || $self;

    my $name = 'default';
    $name = $opts{'name'} if defined $opts{'name'};

    my $ref = { 'name' => $name };
    if ( defined $opts{'host'} ) {
        $DB{$name}{'host'} = $opts{'host'};
    }
    if ( defined $opts{'port'} ) {
        $DB{$name}{'port'} = $opts{'port'};
    }
    if ( defined $opts{'userpass'} ) {
        $DB{$name}{'userpass'} = $opts{'userpass'};
    }
    if ( defined $opts{'check_for_errors'} ) {
        $DB{$name}{'check_for_errors'} = $opts{'check_for_errors'};
    }

    # Get hold of any previously defined connection handle
    if ( defined $DB{$name}{'kdb'} ) {
        $ref->{'kdb'} = $DB{$name}{'kdb'};    # no need for connect
        $DB{$name}{'count'}++;
    }
    return bless $ref, $class;
}

=head2 Connect

To connect to the 'default' server.

    unless($k->connect()) {
        warn "Can't connect to Kdb+ server\n";
    }

To connect to a defined server say 'local22'

    unless($k->connect('local22')) {
        warn "Can't connect to local22 Kdb+ server\n";
    }
 
=cut

sub connect {
    my $self = shift;
    my $name = shift || 'default';

    return undef unless exists $DB{$name}{'host'} && exists $DB{$name}{'port'};

    if ( !defined $DB{$name}{'kdb'} ) {

        # Create a new connection
        # host, port and username password details
        if ( defined $DB{$name}{'userpass'} ) {
            $DB{$name}{'kdb'} = khpu(
                $DB{$name}{'host'},
                $DB{$name}{'port'},
                $DB{$name}{'userpass'}
            );
        }

        # host, port only
        else {
            $DB{$name}{'kdb'} = khp( $DB{$name}{'host'}, $DB{$name}{'port'} );
        }
        unless ( $DB{$name}{'kdb'} > 0 ) {
            carp "Kx->connect failed to connect. " . &whowasi . "\n" if $DEBUG;
            undef $self->{'kdb'};
            undef $DB{$name}{'kdb'};
            return undef;
        }
    }

    # Are we moving between connections
    if ( $self->{'name'} ne $name ) {
        $DB{ $self->{'name'} }{'count'}--;
    }

    $DB{$name}{'count'}++;
    $self->{'kdb'}  = $DB{$name}{'kdb'};
    $self->{'name'} = $name;

    return $self->{'kdb'};
}

=head2 Environment

There are a number of environment details you can glean from the Kdb+
server you are connected to. They are:

    my $arrayref = $k->tables;     # The tables defined
    my $arrayref = $k->funcs;      # The functions defined
    my $arrayref = $k->views;      # The views defined
    my $arrayref = $k->variables;  # The variables defined
    my $arrayref = $k->memory;     # The memory details \w

    my $dir = $k->cwd;              # The current working directory
    my $dir = $k->chdir($newdir);   # Set the cwd
    my $num = $k->GMToffset;        # Offset from GMT for times

If you make changes that effects these environmental details then call
the env() method to update what is known. This module doesn't continually
hassle the server for these details.

    my @details = $k->env;  # Get the environment from the server

    $details[0] => [ tables     ]
    $details[1] => [ funcs      ]
    $details[2] => [ views      ]
    $details[3] => [ variables  ]
    $details[4] => 'GMToffset'
    $details[5] => 'releasedate'
    $details[6] => 'gmt'
    $details[7] => 'localtime'
    $details[8] => [ memory     ]
    $details[7] => 'cwd'

You can also execute OS commands on the server end and gather the results
like this.

    $arref = $k->oscmd("ls -l /");

=cut

sub env {
    my $self = shift;
    return undef unless defined $self->{'kdb'};

    # OK we have aconnection and it is valid. Pick up some meta details
    # from the server
    $self->{'tables'}    = k2parray0( k( $self->{'kdb'}, '\a' ) );
    $self->{'funcs'}     = k2parray0( k( $self->{'kdb'}, '\f' ) );
    $self->{'views'}     = k2parray0( k( $self->{'kdb'}, '\b' ) );
    $self->{'variables'} = k2parray0( k( $self->{'kdb'}, '\v' ) );
    $self->{'GMToffset'} = k2pscalar0( k( $self->{'kdb'}, '(.z.Z-.z.z)*24' ) );
    $self->{'releasedate'} = k2pscalar0( k( $self->{'kdb'}, '.z.k' ) );
    $self->{'gmt'}         = k2pscalar0( k( $self->{'kdb'}, '.z.z' ) );
    $self->{'local'}       = k2pscalar0( k( $self->{'kdb'}, '.z.Z' ) );
    $self->{'mem'} = k2parray0( k( $self->{'kdb'}, '\w' ) );
    $self->{'cwd'} = k2pscalar0( k( $self->{'kdb'}, '\cd' ) );

    return (
        $self->{'tables'},    $self->{'funcs'},     $self->{'views'},
        $self->{'variables'}, $self->{'GMToffset'}, $self->{'releasedate'},
        $self->{'gmt'},       $self->{'local'},     $self->{'mem'},
        $self->{'cwd'},
    );
}

# a:@[.:;"\\ls -l /tmp/zzz > /tmp/.qoscmd 2>&1; cat /tmp/.qoscmd";()]
sub oscmd {
    my $self = shift;
    my $cmd  = shift || return undef;
    my $cap  = shift;

    my $q = '@[.:;"\\\\' . $cmd;

    if ( defined $cap ) {

        # Use cap as a capture file to grap stdout and stderr
        $q .= "> $cap 2>&1; cat $cap";
    }

    $q .= '";()]';
    my $ref = k2parray0( k( $self->{'kdb'}, $q ) );
    my @d = map { $_->[0] } @$ref;
    return \@d;
}

sub memory {
    my $self = shift;
    $self->{'mem'} = k2parray0( k( $self->{'kdb'}, '\w' ) );
    return $self->{'mem'};
}

sub cwd {
    my $self = shift;
    $self->{'cwd'} = k2pscalar0( k( $self->{'kdb'}, '\cd' ) );
    return $self->{'cwd'};
}

sub chdir {
    my $self = shift;
    my $d = shift || '';
    $self->{'cwd'} = k2pscalar0( k( $self->{'kdb'}, "\\cd $d" ) );
    $self->{'cwd'} = k2pscalar0( k( $self->{'kdb'}, '\cd' ) );
    return $self->{'cwd'};
}

sub tables {
    my $self = shift;
    $self->env   unless defined $self->{'tables'};
    return undef unless $self->{'tables'};
    return $self->{'tables'};
}

sub funcs {
    my $self = shift;
    $self->env   unless defined $self->{'funcs'};
    return undef unless $self->{'funcs'};
    return $self->{'funcs'};
}

sub views {
    my $self = shift;
    $self->env   unless defined $self->{'views'};
    return undef unless $self->{'views'};
    return $self->{'views'};
}

sub variables {
    my $self = shift;
    $self->env   unless defined $self->{'variables'};
    return undef unless $self->{'variables'};
    return $self->{'variables'};
}

sub GMToffset {
    my $self = shift;
    $self->env   unless defined $self->{'GMToffset'};
    return undef unless $self->{'GMToffset'};
    return $self->{'GMToffset'};
}

=head2 TABLES

You don't need to use this just use the cmd() interface if you like.
However if your lazy like me.... read on

Each of these accessors have a method name starting with 'T'. To help
distinguish them as cooperating methods.

Create a new table in Kdb+ named mytab with 3 columns col1, col2 and
col3. The keys will be on col1 and col3 This equates to the Q command

    # Q command
    q)mytab:([col1:;col3:] col2:)

    # The long winded Perl way
    $k->Tnew(name=>'mytab',keys=>['col1','col3'],cols=>['col2']);

To add data use Tinsert(). Each row is added in the order defined
above. This line adds 1 into col1, 2 into col3 and 3 into col2 as the
keys are always defined before the other columns.

    $k->Tinsert('mytab',1,2,3);

To do a select over a table use Tselect(). Tselect() takes a variable
name as its first argument. The select will be executed and assigned to
the variable you define. This way no data is passed from Kdb+ to the
client until it is needed.

    $k->Tselect('a','select from mytab where col1>4');

This is really just the same as

    # q command
    a:select from mytab where col1>4

To get the details of the stored selection

    my $numrows = $k->Tnumrows('a');
    my $numcols = $k->Tnumcols('a');

This only works on variables that are tables returned from a selection.

Tget() Tindex() Tcol() and Theader() are only useful once you have done a
Tget(). 

Remember it is probably better to only pull back small tables less than
say a few tens of thousand of rows as you'll eat up memory fast.

You may have run a number of Tselects() and now wish to pull back the
data. To do this use Tget()

    $k->Tget('table');   # table must be a table in the server

Tget() can also be used with select type queries that return a table as
their result. It also handles indexed tables better than the cmd()
method.

To get access to random values in the returned table from Tget().

    $val = $k->Tindex(row,col);

This only works for simple tables holding scalars in each row. Don't try
this if the index would point to a mulit-valued list. Actually it sort of
works for lists and when it does $val is an array reference. If you have
troubles use Tcol().

To get the list of column names as Kdb+ knows them.

    my $header = $k->Theader();
	print "@$header\n";

To get the meta data for a table as defined in KDB do this.

    my @meta = $k->Tmeta($table);
    foreach(@meta)
    {
    	print "(name type) => (@$_)\n";
    }


To get a Perl reference to a column of data from the table (as K is
column oriented) do the following:

    my $colref = $k->Tcol(0);   # get the zeroth column
    print "Column 0 data is: @$colref\n";

I advise against using this on large columns or tables as it is very
memory inefficent. Better to use $k->cmd() interface to pull back
exactly what you want first. The column reference above is a Perl copy of
the data structure held in Kdb+ memory format in the client. This can be
over 3 times larger in core than the Kdb+ data.

If you need to access data via rows then use $k->Trow(). Given a row
number it will return a reference to the row. The first row is at zero 0.

    my $row = $k->Trow(0);   # get the zeroth row
    print "Row 0 data is: @$row\n";

Finally to delete or remove a table by name from the server:

    $k->Tdelete('table');

Here is a list of the complete table methods we have so far:

    $k->Tnew(name=>'thename',keys=>[],cols=>[]);
    $k->Tinsert('table',1,2,3);
    $k->Tbulkinsert('table',col1=>[],col2=>[],...);
    $k->Tget('select statement');
    $scalar = $k->Tindex($row,$col);
    $arref  = $k->Tcol(2);      # 3rd col vector
    $arref  = $k->Trow(2);      # 3rd row
    $arref  = $k->Theader;
    $x      = $k->Tnumrows;
    $y      = $k->Tnumcols;
    $k->Tselect('table','select statement');
    $k->Tsave('table','file');
    $k->Tappend('table','file');
    $k->Tload('table','file');
    $k->Tdelete('table');

If you want a faster bulk insert function use:


    $k->Tfastbulkinsert('mytab',$col1,$col2,$col3...);

Here col1 col2 etc are infact in core Kdb+ structures and must be in the
same order as the declaration use when you used Tnew(). This is almost 3
times faster than Tbulkinsert but uses more memory in the client. See the
test files that came with this module for more details on how it is used.

=cut

sub Tnew {
    my $self = shift;
    my %arg  = @_;

    return undef unless defined $self->{'kdb'};
    return undef unless defined $arg{'name'};
    return undef unless defined $arg{'cols'};

    delete $self->{'COLS'} if defined $self->{'COLS'};

    # string to create the table
    my $q = $arg{'name'} . ":([";

    # string to create a bulk insert function
    my $b = 'pblkinsert_' . $arg{'name'} . ':{insert[`' . $arg{'name'} . '](';

    my $i = 0;
    if ( defined $arg{'keys'} ) {
        foreach my $key ( @{ $arg{'keys'} } ) {
            $q .= $key . ':();';
            $b .= $key . ":(x[$i]);";
            $i++;
        }
        chop($q);    # one ; too many
    }
    $q .= "]";
    foreach my $c ( @{ $arg{'cols'} } ) {
        $q .= $c . ':();';
        $b .= $c . ":(x[$i]);";
        $i++;
    }
    chop($q);
    chop($b);
    $q .= ')';       # mytab:([col1:();col3:()]col2:())
    $b .= ')}';      # pblkinsert_mytab:{insert[`mytab](c1:(x[0]);c2:(x[1]))}

    # Create the table
    my $k = k( $self->{'kdb'}, $q );
    if ( $k == 0 ) {
        dor0($k);    # release memory
        return undef;
    }
    if ( kType($k) < 0 ) {
        carp "Kx->tablecreate error ", k2pscalar($k), "\n";
        dor0($k);    # release memory
        return undef;
    }
    dor0($k);        # release memory

    # Create the bulkinsert function
    $k = k( $self->{'kdb'}, $b );
    if ( $k == 0 ) {
        dor0($k);    # release memory
        return undef;
    }
    if ( kType($k) < 0 ) {
        carp "Kx->tablecreate bulkinsert function error ", k2pscalar($k), "\n";
        dor0($k);    # release memory
        return undef;
    }

    dor0($k);        # release memory
    return 1;
}

sub Tdelete {
    my $self = shift;
    my $var = shift || return undef;

    delete $self->{'COLS'} if defined $self->{'COLS'};

    #$self->{'K'}  = k($self->{'kdb'},"$var: null");
    # .[`.;();_;`d]  will remove the d symbol from the current workspace
    # This uses the Dot Fucntional form of Amend .[d;i;f;y] where
    #    d is a dictionary, `d do it in place
    #    i is and index, possibly multi level
    #    f is a function to apply
    #    y is the right hand side of a dyadic function
    #
    # So `. is the symbol name for the current workplace to be Ammeded in
    # place
    # () is an index for the whole domain of .
    # _  is the drop function
    # `d is the symbol name we wish to drop
    my $k = k( $self->{'kdb'}, ".[`.;();_;`$var]" );
    dor0($k);    # release memory
    return 1;
}

sub check_for_errors {
    my $k = shift;
    my $q = shift || "";

    if ( $k == 0 ) {
        carp "Undefined K structure\n";
        return 0;
    }
    if ( kType($k) == -128 ) {
        carp "K error ", k2pscalar($k), " $q\n";
        return 0;
    }
    return 1;
}

#    $k->Tinsert('mytab',1,2,3); a single row
#
sub Tinsert {
    my $self  = shift;
    my $table = shift;

    return undef unless defined $self->{'kdb'};

    delete $self->{'COLS'} if defined $self->{'COLS'};

    # q)insert[`mytab](1;2;3)
    my $q = 'insert[`' . $table . '](' . join( ';', @_ ) . ')';

    my $k = k( $self->{'kdb'}, $q );
    my $r = 1;
    if ( exists $self->{'check_for_errors'} ) {
        $r = check_for_errors( $k, $q );
    }
    dor0($k);
    return $r;
}

#    $k->bulkinsert('mytab',$col1,$col2,$col3...);
#
sub bulkinsert {
    my $self  = shift;
    my $table = shift;

    return undef unless defined $self->{'kdb'};

    # Create the argument list
    my $cols = ktn( 0, scalar @_ );
    for ( my $i = 0 ; $i < @_ ; $i++ ) {
        setKarraymixed( $cols, $i, $_[$i] ) || croak "Can't setKarraymixed ";
    }

    k1( -( $self->{'kdb'} ), "pblkinsert_$table", $cols );
    return 1;
}

#    $k->Tbulkinsert('mytab',$k=>$colref,$k1=>$col1ref);
#
sub Tbulkinsert {
    my $self  = shift;
    my $table = shift;

    return undef unless defined $self->{'kdb'};

    # q)insert[`mytab](id:($id);p:($prop);v:($v);tm:($z))
    my $q = 'insert[`' . $table . '](';
    while (@_) {
        my $key  = shift @_;
        my $aref = shift @_;
        return undef unless $aref;
        $q .= "$key:(" . join( ';', @$aref ) . ');';
    }
    chop $q;
    $q .= ')';

    k( -( $self->{'kdb'} ), $q );
    return 1;
}

sub Tsave {
    my $self  = shift;
    my $table = shift;
    my $file  = shift;

    return undef unless defined $table;
    if ( !defined $file && defined $table ) {

        # Then filename os tablename
        $file = $table;
    }

    return undef unless defined $self->{'kdb'};

    # q).[`:filename;();:;tablename]
    my $q = '.[`$":' . $file . '";();:;' . $table . ']';

    my $k = k( $self->{'kdb'}, $q );
    my $r = check_for_errors( $k, $q );
    dor0($k);
    return $r;
}

sub Tappend {
    my $self  = shift;
    my $table = shift;
    my $file  = shift;

    return undef unless defined $table;
    if ( !defined $file && defined $table ) {

        # Then filename os tablename
        $file = $table;
    }

    return undef unless defined $self->{'kdb'};

    # q).[`:filename;();:;tablename]
    my $q = '.[`$":' . $file . '";();,;' . $table . ']';

    my $k = k( $self->{'kdb'}, $q );
    my $r = check_for_errors( $k, $q );
    dor0($k);
    return $r;
}

sub Tload {
    my $self  = shift;
    my $table = shift;
    my $file  = shift;

    return undef unless defined $table;
    if ( !defined $file && defined $table ) {

        # Then filename os tablename
        $file = $table;
    }

    return undef unless defined $self->{'kdb'};

    # q).[`:filename;();:;tablename]
    my $q = "$table: value`\$\":$file\"";

    my $k = k( $self->{'kdb'}, $q );
    my $r = check_for_errors( $k, $q );
    dor0($k);
    return $r;
}

#    $k->Tselect('a','select sum size by sym from trade where date=2006.09.25');
#
#To get the details of the stored selection
#
#    my $numrows = $k->Tnumrows('a');
#    my $numcols = $k->Tnumcols('a');
sub Tselect {
    my $self = shift;
    my $table = shift || croak;

    return undef unless defined $self->{'kdb'};

    # q)a: select col1 from mytab where col1 > 7
    my $q = $table . ':' . join( '', @_ );

    my $k = k( $self->{'kdb'}, $q );
    my $r = check_for_errors( $k, $q );
    dor0($k);
    return $r;
}

sub Tnumrows {
    my $self = shift;
    my $table = shift || croak;

    return undef unless defined $self->{'kdb'};

    # q)count mytab
    my $q = "count $table";

    my $k = k( $self->{'kdb'}, $q );
    my $rows = k2pscalar0($k);

    return $rows;
}

sub Tnumcols {
    my $self = shift;
    my $table = shift || croak;

    return undef unless defined $self->{'kdb'};

    my $q = "cols $table";

    my $k       = k( $self->{'kdb'}, $q );
    my $cols    = k2parray0($k);
    my $numcols = scalar @$cols;

    return $numcols;
}

sub Tget {
    my $self = shift;
    my $cmd = shift || return undef;

    dor0( $self->{'K'} ) if defined $self->{'K'};    # release memory
    return undef unless defined $self->{'kdb'};

    $self->{'K'} = kTable( $self->{'kdb'}, $cmd );
    if ( $self->{'K'} == 0 ) {
        return undef;
    }
    if ( kType( $self->{'K'} ) < 0 ) {
        carp "Kx->Tget error $cmd", k2pscalar0( $self->{'K'} ), "\n";
        return undef;
    }

    $self->{'colnames'} = k2parray( kTableH( $self->{'K'} ) );
    $self->{'NUMROWS'}  = kTableNumRows( $self->{'K'} );
    $self->{'NUMCOLS'}  = kTableNumCols( $self->{'K'} );
    $self->{'COLS'}     = kTableCols( $self->{'K'} );

    return ( $self->{'NUMROWS'}, $self->{'NUMCOLS'} );
}

sub Tmeta {
    my $self  = shift;
    my $table = shift;

    #my $q    = "select c,t from meta $table";
    my $q = "meta $table";
    my $meta = kTable( $self->{'kdb'}, $q );
    return undef if $meta == 0;
    if ( kType($meta) < 0 ) {
        carp "Kx->meta error $q", k2pscalar0($meta), "\n";
        return undef;
    }

    my $rows = kTableNumRows($meta);
    my @m    = ();
    for ( my $i = 0 ; $i < $rows ; $i++ ) {
        my $type = kTableIndex( $meta, $i, 1 );    # Version 2.2 support
        if ( $type =~ /^\d+/ ) {
            $type = chr($type);
        }
        push( @m, [ kTableIndex( $meta, $i, 0 ), $type ] );
    }
    dor0($meta);

    return @m;
}

sub Tcol {
    my $self = shift;
    my $col  = shift;
    return undef unless defined $self->{'COLS'};
    return undef unless $col >= 0 && $col < $self->{'NUMCOLS'};

    my $c = kStructi( $self->{'COLS'}, $col );
    return k2parray($c);
}

sub Tindex {
    my $self   = shift;
    my $row    = shift;
    my $column = shift;

    return undef unless defined $self->{'K'};
    return undef unless defined $self->{'COLS'};
    return undef unless $column >= 0 && $column < $self->{'NUMCOLS'};
    return undef unless $row >= 0 && $row < $self->{'NUMROWS'};

    return kTableIndex( $self->{'K'}, $row, $column );
}

sub Trow {
    my $self = shift;
    my $row  = shift;

    return undef unless defined $self->{'K'};
    return undef unless defined $self->{'COLS'};
    return undef unless $row >= 0 && $row < $self->{'NUMROWS'};

    my @rtn    = ();
    my $colidx = $self->{'NUMCOLS'} - 1;
    for my $col ( 0 .. $colidx ) {
        push( @rtn, kTableIndex( $self->{'K'}, $row, $col ) );
    }

    return \@rtn;
}

sub Theader {
    my $self = shift;
    return undef unless defined $self->{'K'};
    return undef unless defined $self->{'COLS'};

    return k2parray( kTableH( $self->{'K'} ) );
}

=head2 COMMANDS

Execute the code on an already accessable Kdb+ server. The query
is executed and the results are held in K structures in RAM. Example

    $return = $k->cmd('b:til 100');

If you just what to send a command to the Kdb+ server and not wait then
use the following. No return value is provided.

    $k->whenever('b:til 100');

The cmd() method also allows up to two extra arguments that are normally
K objects. You normally call cmd() this way when you have a function to
call. Here is a dodgy example.

    my $data = $k->listof(length($arrsym), Kx::KG());  # list of bytes
    $data->setbin($arrsym);

    $result = $k->cmd('{[x]insert[`mytab](0;x;.z.z)}', $data->kval);

The cmd() function will return a reference to an array if the Q command
returns a list. It will return a simple scalar if the result is a scalar
response from Q. It will return a hash reference if the return result
from Q is either  table/keyed table/dictionary. You need to know what you
are doing so can know what the result is (or use Perl's ref()).

Do not execute queries that return large 'keyed' tables as a copy of the table
in unkeyed form is held to convert to a Perl Hash before being freed.

Note: cmd() does not convert a keyed table to an unkeyed table in memory.
It holds onto what was passed back from KDB+ as is. If you want get at
the underlying K structure and change it use Tget() instead. Tget() will
convert a keyed table to an unkeyed table and hold it in memory.

If you have a Q script that you wish to run against the Kdb+ server you
can use the do(file) method. Any error in your script that is caught will
stop do(file) from proceeding. If you don't care when it is done then use
dolater(file).

Both do() and dolater() don't return anything useful. They just blindly
execute each line of Q against the server. If you want to check each
command and do stuff as a result then use cmd() and check the result.

An example file name foo.txt holds the lines:

    t:([]a:();b:())
    insert[`t](`a;10.70)
    insert[`t](`b;-5.6)
    insert[`t](`c;21.73)

You can run that file by doing this:

    $k->do("foo.txt");

=cut

sub do {
    my $self = shift;
    my $file = shift || return undef;

    my $k;
    open( F, $file ) || return undef;
    while (<F>) {
        chomp;
        $k = k( $self->{'kdb'}, $_ );
        if ( $k == 0 ) {
            dor0($k);    # release memory
            return undef;
        }
        if ( kType($k) == -128 ) {
            my $err = k2pscalar0($k);
            carp "Kx->do error $file $err on line $_\n";
            return $err;
        }
        dor0($k);        # release memory
    }
    return 1;
}

sub cmd {
    my $self = shift;
    my $cmd  = shift || return undef;
    my @arg  = @_;

    my $k;
    if ( @arg > 2 ) {
        carp "Kx->cmd(self,cmd,arg1,arg2) max extra args is 2, use lists";
        return undef;
    }
    return undef unless defined $self->{'kdb'};

    if ( @arg == 1 ) {
        $k = k1( $self->{'kdb'}, $cmd, $arg[0] );
    }
    elsif ( @arg == 2 ) {
        $k = k2( $self->{'kdb'}, $cmd, $arg[0], $arg[1] );
    }
    else {
        $k = k( $self->{'kdb'}, $cmd );
    }

    if ( $k == 0 ) {
        return undef;
    }

    dor0( $self->{'K'} ) if defined $self->{'K'};    # release memory
    $self->{'K'} = $k;
    _val($k);
}

sub whenever {
    my $self = shift;
    my $cmd = shift || return undef;

    return undef unless defined $self->{'kdb'};

    k( -( $self->{'kdb'} ), $cmd );
    return undef;
}

=head2 ATOMS and STRUCTURES

To create Kdb+ atoms locally in RAM use the following calls.

    my $d;
    $d=$k->bool(0);           # boolean
    $d=$k->byte(100);         # char
    $d=$k->char(ord('a'));    # char
    $d=$k->short(20);
    $d=$k->int(70);
    $d=$k->long(93939);
    $d=$k->real(20.44);        # remember 20.44 may look close as a real
    $d=$k->float(20.44);       # should look closer to 20.44 as a float
    $d=$k->sym('mysymbol');    # A Kdb+ symbol
    $d=$k->date(2007,4,22);    # integer encoded date year, month, day
    $d=$k->dt(time());         # Kdb+ datetime from Unix epoch
    $d=$k->tm(100);            # Time type in milliseconds

These allow for fine grained control over the 'type' of K object you
want. If you don't mind particularly about the type conversions then you
can use perl2K() like this.

    $d = $k->perl2K('mysymbol');
    $d = $k->perl2K([qw/this will be a K list of symbols/]);
    $d = $k->perl2K({this => 1, that => 2, 'is a' => 'dict'});

To get a Perl value back from a Kdb+ atom try this;

    my $val = $d->val();

To get the internal value back from a Kdb+ atom try this;

    my $kval = $k->kval;  # used in $x->cmd('func', $kval)

As a further comment on the date() method. When you look at the value
retuned from a date() call it is in epoch seconds.

    my $date = $k->date(2007,4,22);
    print scalar localtime($date->val),"\n";

Further more, KDB+ Datetimes are held as a C double in memory. The
integral part is the number of days since 1/1/2000 and the fractional
part is the fraction of the day. You have some control over how datetimes
are returned from KDB+ back into Perl data structures. By default a
conversion to Unix epoch seconds will be made. You can also get epoch seconds
with milliseconds and you can also turn off conversion all together.

    Kx::__Z2epoch(0);   # turn off Kdb+ to Unix epoch conversion
    Kx::__Z2epoch(1);   # turn on Kdb+ to Unix epoch conversion (default)
    Kx::__Z2epoch(2);   # turn on Kdb+ to Unix epoch conversion plus millisecs

These have immediate effects on how datetimes are converted into Perl
data structures. These do not effect what is held in RAM after a call to
KDB+ has been made, just how they are converted into Perl.

These methods use the underlying functions as listed below. Don't use
these unless you know what your doing. They are listed here for
completeness and so you can use them if you really want. But don't.

    Kx::kb(integer)     => Create boolean 0|1
    Kx::kg(integer)     => Create a byte/char
    Kx::kh(integer)     => Create a short
    Kx::ki(integer)     => Create and integer
    Kx::kj(longval)     => Create a long
    Kx::ke(realval)     => Create a real
    Kx::kf(floatval)    => Create a float
    Kx::kc(charval)     => Create a char from an int ord()
    Kx::ks(symbol)      => Create a symbol from a string
    Kx::kd(date)        => Create a date - See K dates
    Kx::kz(datetime)    => Create a datetime - See K dates
    Kx::kt(time)        => Create a time

    Kx::p2k($ref)       => return a K structure describing the Reference
    Kx::k2p(K)          => return a Perl structure from a Kdb+ structure

    Kx::k2pscalar(K)    => return a scalar from a Kdb+ atom
    Kx::k2parray(K)     => return an array from a Kdb+ list
    Kx::k2phash(K)      => return a hash from a Kdb+ dict/table

    Kx::phash2k($href)  => return a Kdb+ dict from a Perl hash ref
    Kx::parray2k($aref) => return a Kdb+ list from a Perl array ref
    Kx::pscalar2k($srf) => return a Kdb+ atom from a Perl scalar ref

Example:

    # Simple create
    my $bool = $k->bool(0);
    print "My boolean in K is ",$bool->val,"\n";

=cut

# Create an atom in a generic fashion not an OO function call. Creates a
# K object as its return value
sub _atom {
    my ( $val, $code ) = @_;

    # Check for null
    return (undef) unless ( defined $val );

    # Default to creating symbols
    $code = \&ks unless defined $code;

    my $k = Kx->new();
    $k->{'K'} = $code->($val);
    return $k;
}

# There is very little checking done by this code.
sub bool  { _atom( $_[1], \&kb ); }
sub byte  { _atom( $_[1], \&kg ); }
sub short { _atom( $_[1], \&kh ); }
sub int   { _atom( $_[1], \&ki ); }
sub long  { _atom( $_[1], \&kj ); }
sub real  { _atom( $_[1], \&ke ); }
sub float { _atom( $_[1], \&kf ); }
sub char  { _atom( $_[1], \&kc ); }
sub sym   { _atom( $_[1], \&ks ); }
sub date { _atom( ymd( $_[1], $_[2], $_[3] ), \&kd ); }
sub month  { _atom( $_[1],            \&ki ); }
sub second { _atom( $_[1],            \&ki ); }
sub dt     { _atom( epoch2Z( $_[1] ), \&kz ); }
sub tm     { _atom( $_[1],            \&kt ); }

sub perl2k {
    my $self = shift;
    my $v = shift || return undef;

    my $k = Kx->new();
    if ( ref($v) ) {
        if ( ref($v) eq 'SCALAR' || ref($v) eq 'ARRAY' || ref($v) eq 'HASH' ) {
            $k->{'K'} = p2k($v);
        }
        else {
            carp("Kx->perl2k(x): x can only be a ref to scalar, array, hash");
        }
    }
    else {
        $k->{'K'} = p2k( \$v );
    }
    return $k;
}

sub val {
    my $self = shift;
    return _val( $self->{'K'} );
}

sub _val {
    my $k = shift;

    return undef unless defined $k;

    my $type = kType($k);
    if ( $type == -128 )    # Its an error
    {
        my $err = k2pscalar0($k);
        carp "K error: $err \n";
        return $err;
    }
    elsif ( $type >= 0 && $type < KT() )    # Its a list
    {
        my $ref = k2parray($k);

        # Now if its a list of char vals or a list of bytes then we
        # convert it to a single string, possibly binary
        if ( $type == KG() || $type == KC() ) {
            return $ref->[0];
        }
        else    # default return array ref
        {
            return $ref;
        }
    }
    elsif ( $type < 0 || $type == 98 || $type == 99 )    # Scalar/Hash etc
    {
        return k2p($k);
    }
    else    # nothing to return so say OK
    {
        return 1;
    }
}

sub kval {
    return undef unless defined $_[0]->{'K'};
    return $_[0]->{'K'};
}

=head2 LISTS

=head3 Simple Lists

These list functions create in memory local lists outside of any 'q'
running process. These will allow you to create very large simple lists
without blowing out all your memory.

To create a simple Kdb+ list of a single type use the listof() function.
The type of the list is passed in as the second aregument and can be one
of:

    Kx::KC()  char
    Kx::KD()  date yyyy mm dd
    Kx::KE()  real
    Kx::KF()  float
    Kx::KG()  byte
    Kx::KH()  short
    Kx::KI()  integer
    Kx::KJ()  long
    Kx::KM()  month
    Kx::KS()  symbol (internalised string)
    Kx::KT()  time
    Kx::KU()  minute
    Kx::KV()  second
    Kx::KZ()  datetime epoch seconds

Example simple lists:

    my $list = $k->listof(20,Kx::KS());      # List of 20 symbols
    for( my $i=0; $i < 20; $i++)
    {
        $list->at($i,"symbol$i");
    }

    # To get at the 4th element
    my $sym = $list->at(3);     # symbol3

    my $perl_list = $list->list;
    print "Symbols are @$perl_list\n";

    # dates
    $d = $k->listof(20,Kx::KD());
    for( my $i=0; $i < 20; $i++)
    {
        $d->at($i,2007,4,$i+1);  # 20070401 -> 20070421
    }

    # Add an extra date to the end of the list
    my $day = $k->date(2007,4,30);
    $d->joinatom($day->kval);

There is also another method defined setbin()  that sets binary
data into a list of bytes. You can use this to save serialised Perl
data structures into Kdb+ tables (much like a blob or text field in SQL
DBs).  Here is an example:

    use Kx;
    use Compress::Zlib qw/compress uncompress/;
    use Data::Dumper;
    $Data::Dumper::Indent = 0; # no newlines, important
    
    my $k = Kx->new(host=>"localhost", port=>2222, check_for_errors=>1);
    $k->connect() or die "Can't connect to Kdb+ server";
    
    # create new table in q
    $k->Tnew(name=>'mytab',cols=>[qw/id data ts/]);
    
    # Build a large complicated Perl structure.
    my $arr = { a=>['a','b','c',1,2,3], b=>'this is a test'};
    for (0..10000) {
        $arr->{$_} = {$_ => $_};
        $arr->{"a$_"} = [$_, $_];
    }
    
    # Serialise it as a compressed piece of data
    my $arrsym =  Dumper($arr);
    print "Dumper size is: ", length $arrsym, "\n";
    $arrsym = compress( $arrsym );
    print "Compress Dumper size is: ", length $arrsym, "\n";
    
    # An in memory Kdb+ list of bytes to hold the compressed data
    my $data = $k->listof(length($arrsym),Kx::KG());  # list of length bytes
    $data->setbin($arrsym);
    
    # Insert it into a table using a function call.
    $k->cmd('{[x]insert[`mytab](0;x;.z.z)}',$data->kval);
    
    # Select a single row from the table, and return it's data
    $binary = $k->cmd('(select data from mytab where id=0)[0;`data]');
    
    # Get the data back into Perl string form
    $arrsym = uncompress($binary);
    #print $arrsym,"\n";
    
    # Eval the string into a Perl data structure the hard way
    my $VAR1;
    eval $arrsym;
    print $VAR1->{'b'},"\n";

=head3 Mixed Lists

    # The zero in line below says its to be a mixed list
    my $list = $k->listof(40,0); # mixed list 40 elements
    $list->at(0,$k->float(22.22));

    $list->at(1,$k->sym('this is a test'));
    .
    .
    $list->at(39,$k->date(2007,2,28));

This is handy for creating multiple arguments to a KDB+ function call.

=cut

sub joinatom {
    my $self = shift;
    my $atom = shift;

    no warnings;
    $self->{'K'} = call_ja( $self->{'K'}, $atom->val );
}

sub list {
    my $self = shift;
    return undef unless defined $self->{'K'};

    return k2parray( $self->{'K'} );
}

sub av2k {
    my $self = shift;
    my ( $typ, $aref ) = @_;

    unless ( defined $typ && $typ > 0 && $typ < 20 ) {
        carp "Kx->av2k(self,x,typ) typ must be @TYP\n";
        return undef;
    }

    dor0( $self->{'K'} ) if defined $self->{'K'};    # release memory

    $self->{'K'} = newKarray( $typ, $aref );
    return $self;
}

sub listof {
    my $self = shift;
    my ( $x, $typ ) = @_;

    if ( $x <= 0 ) {
        carp "Kx->listof(self,x,typ) x=$x less than zero ";
        return undef;
    }
    unless ( defined $typ && $typ >= 0 && $typ < 20 ) {
        carp "Kx->listof(self,x,typ) typ must be @TYP\n";
        return undef;
    }

    my $k = Kx->new();
    $k->{'K'} = ktn( $typ, $x );
    return $k;
}

sub getbin {
    my $self = shift;
    my $ref = getKarraybinary( $self->{'K'}, 0, 0 );
    return $ref;
}

sub setbin {
    my $self = shift;
    my ($val) = @_;

    unless ( setKarraybinary( $self->{'K'}, 0, $val ) ) {
        carp "Kx->setbin error in binary copy\n";
        return 0;
    }
    return 1;
}

sub at {
    my $self = shift;
    my ( $x, @val ) = @_;

    # What type am I?
    my $mytype = kType( $self->{'K'} );

    # I need to be a list
    unless ( $mytype >= 0 ) {
        carp "Can't call Kx->at() on a non list K onject";
        return undef;
    }

    # If it is a set operation
    if ( defined $val[0] ) {
        my $k;

        # Want to store only Kdb+ structure directly or via an object for
        # mixed lists and scalars for simple lists.
        # Here we work out where the $k variable will come from
        if ( $mytype == 0 && ref( $val[0] ) eq 'KstructPtr' ) {
            $k = $val[0];
        }
        elsif ( $mytype == 0 && ref( $val[0] ) eq 'Kx' ) {
            $k = $val[0]->{'K'};
        }
        elsif ( $mytype > 0 && $#val == 2 )    # Assume a date yyyy,mm,dd
        {
            $k = ymd(@val);
        }
        elsif ( $mytype > 0 ) {
            $k = $val[0];
        }
        else {
            carp "Kx->at(pos,val) Invalid val type for this list type";
            return undef;
        }

        # Am I a List of K objects?
        if ( $mytype == 0 ) {

            # $k is of type K
            unless ( setKarraymixed( $self->{'K'}, $x, $k ) ) {
                carp "Kx->at(pos,val) pos=$x out of bounds? ";
            }
            return 0;
        }
        else    # Simple list
        {
            # $k is a Perl scalar
            unless ( setKarraysimple( $self->{'K'}, $x, $k ) ) {
                carp "Kx->at(pos,val) type mismatch or pos=$x out of bounds";
            }
            return 0;
        }
        return undef;
    }
    else        # A get operation
    {
        return getKarray( $self->{'K'}, $x );
    }
}

=head2 Utility Methods

$k->dump0() will return a string describing the under lying K structure.

Kx::dump($k) will print out the K structure of $k

$sym = Kx::makesym("string") will convert a simple string into a quoted
symbol suitable for usage in KDB+

make_C() will convert its argument into a suitable string quoted
as a KDB+ character list.

    my $c = Kx::make_C("now is\tthe \n time for \n help");

There is also make_s():

    my $sym = Kx::make_s("a symbol"); # `$"a symbol"
    my $sym = Kx::make_s(undef);      # a null symbol `

=cut

sub make_s {
    if ( !defined $_[0] ) {
        return '`';
    }
    return "`\$\"$_[0]\"";
}

sub make_C {
    if ( !defined $_[0] ) {
        return $NULL{'char'};
    }
    return '"c"$0x'
      . join( '', map { sprintf "%02x", $_ } unpack( "C*", $_[0] ) );
}

sub make_i {
    if ( !defined $_[0] ) {
        return $NULL{'int'};
    }
    return $_[0] + 0;
}

sub _getepoch {
    if ( $_[0] =~ /^now/io ) {
        return time;
    }
    elsif ( $_[0] =~ /^never/io ) {
        return 1999999999;
    }
    else {
        return $_[0];
    }
}

sub make_z_epoch_gmt {
    if ( !defined $_[0] ) {
        return $NULL{'datetime'};
    }
    return POSIX::strftime "%Y.%m.%dT%H:%M:%S", gmtime( _getepoch( $_[0] ) );
}

sub make_z_epoch_local {
    if ( !defined $_[0] ) {
        return $NULL{'datetime'};
    }
    return POSIX::strftime "%Y.%m.%dT%H:%M:%S", localtime( _getepoch( $_[0] ) );
}

sub dump0 {
    my $self = shift;

    return undef unless defined $self->{'K'};
    my $refcnt = kRefCnt( $self->{'K'} );
    my $type   = kType( $self->{'K'} );
    my $att    = kAtt( $self->{'K'} );
    my $num    = kNum( $self->{'K'} );
    my $val    = k2pscalar( $self->{'K'} );

    return
      "{Value: $val, RefCnt=>$refcnt, Type=>$type, Att=>$att, Num=>$num}\n";

}

sub dump {
    my $k = shift;

    return undef unless defined $k;

    my $refcnt = kRefCnt($k);
    my $type   = kType($k);
    my $att    = kAtt($k);
    my $num    = kNum($k);
    my $val    = k2pscalar($k) || 'no value';

    print "{Value: $val, RefCnt=>$refcnt, Type=>$type, Att=>$att, Num=>$num}\n";

}

sub DESTROY {
    my $self = shift;
    my $name = $self->{'name'} || return;

    return unless defined $self->{'K'};
    return unless ref( $self->{'K'} ) eq 'KstructPtr';

    dor0( $self->{'K'} );

    $DB{$name}{'count'}--;
    if ( $DB{$name}{'count'} <= 0 && exists $DB{$name}{'kdb'} ) {
        POSIX::close( $DB{$name}{'kdb'} );
        undef( $DB{$name} );
    }
    undef $self->{'K'};
    undef $self->{'COLS'};
}

sub dor0 {
    my $k = shift;
    unless ( defined $k ) {
        carp &whowasi;
        carp "Kx::dor0() must be called with an argument: ";
    }
    unless ( ref($k) eq 'KstructPtr' ) {
        carp &whowasi;
        carp "Kx::dor0() argument not a KstructPtr: ", ref($k), ": ";
    }
    r0($k);
}

#####################################################################
#                           K List package                          #
#####################################################################
#       A class implementing a tied ordinary array should define the following
#       methods: TIEARRAY, FETCH, STORE, FETCHSIZE, STORESIZE and perhaps UNTIE
#       and/or DESTROY.
#
#       FETCHSIZE and STORESIZE are used to provide $#array and equivalent
#       "scalar(@array)" access.
#
#       The methods POP, PUSH, SHIFT, UNSHIFT, SPLICE, DELETE, and EXISTS
#

=head1 Kx::LIST

You may wish to tie a Perl array to a Kdb+ variable. Well, you can do
that as well. Try something like this:

    use Kx;
    
    my %config = (
        host=>"localhost",
        port=>2222,
        userpass=>'user:pass',    # optional
        type=>'symbol',
        list=>'d',
        create=>1
    );
    tie(@a, 'Kx::LIST', %config);
    
    # push lost of stuff on an array
    my @array = (qw/aaaa bbbbb ccccc ddddddddd e f j h i j k l/) x 30000
    ;
    push(@a,@array);
    push(@a,@array);
    push(@a,@array);
    print "\@a has ", scalar(@a)," elements\n";
    
    # Store
    $a[3] = "Help me";
    print "Elementt 3 is ",$a[3],"\n";

All the functions defined in perltie for lists are included.

Note: 'type' is a Kdb+ type as defined in Types below - it is the
type for the array.  Only simple types are allowed at the moment.

=cut

package Kx::LIST;
$Kx::LIST::VERSION = '0.042';
use 5.008;
use strict;
use warnings;
use Carp;
sub whowasi { ( caller(1) )[3] . '()' }

sub TIEARRAY {
    carp &whowasi if $DEBUG;
    my $class = shift;
    my %opts  = @_;
    my $d;    # list

    my $name = $opts{'name'} || 'default';
    my $ref = { 'name' => $name };
    if ( defined $opts{'host'} ) {
        $DB{$name}{'host'} = $opts{'host'};
    }
    if ( defined $opts{'port'} ) {
        $DB{$name}{'port'} = $opts{'port'};
    }
    if ( defined $opts{'list'} ) {
        $ref->{'list'} = $opts{'list'};
    }
    if ( defined $opts{'create'} ) {
        $ref->{'create'} = 1;
    }
    my $type = $opts{'type'} || 'symbol';
    $ref->{'type'} = $type;

    return undef unless exists $CAST{$type};
    return undef
      unless defined $DB{$name}{'host'} && defined $DB{$name}{'port'};
    return undef unless defined $ref->{'list'};

    # Get hold of any previously defined connection handle
    if ( defined $DB{$name}{'kdb'} ) {
        $ref->{'kdb'} = $DB{$name}{'kdb'};    # no need for connect
        $DB{$name}{'count'}++;
    }
    else                                      # get connected a new
    {
        if ( defined $DB{$name}{'userpass'} ) {
            $ref->{'kdb'} = Kx::khpu(
                $DB{$name}{'host'},
                $DB{$name}{'port'},
                $DB{$name}{'userpass'}
            );
        }

        # host, port only
        else {
            $ref->{'kdb'} = Kx::khp( $DB{$name}{'host'}, $DB{$name}{'port'} );
        }
        unless ( $ref->{'kdb'} > 0 ) {
            undef $ref->{'kdb'};
            return undef;
        }
        $DB{$name}{'kdb'} = $ref->{'kdb'};
        $DB{$name}{'count'}++;
    }

    # OK check if the variable already exists. If not then create it
    my $var = Kx::k2parray0( Kx::k( $ref->{'kdb'}, '\v' ) );
    $d = $ref->{'list'};
    if ( !grep( /^$d$/, @$var ) || defined $ref->{'create'} ) {
        my $r = Kx::k( $ref->{'kdb'}, "$d:()" );
        if ( $r == 0 ) {
            carp "Undefined K structure in TIELIST\n";
            return undef;
        }
        if ( Kx::kType($r) < 0 ) {
            carp "Kx::LIST error ", Kx::k2pscalar($r), "\n";
            return undef;
        }
        $ref->{'count'} = 0;
    }

    return bless $ref, $class;
}

sub FETCH {
    my $self = shift;
    my $i    = shift;

    my $list = $self->{'list'};
    return undef if $i < 0 || $i >= $self->{'count'};

    $self->{'val'} = Kx::k2pscalar0( Kx::k( $self->{'kdb'}, "$list\[$i\]" ) );
    return $self->{'val'};
}

sub STORE {
    my $self = shift;
    my $i    = shift;
    my $val  = shift;
    my $list = $self->{'list'};

    return undef if $i < 0;
    $self->EXTEND($i) if $i >= $self->{'count'};

    # Cast the value
    $val = $CAST{ $self->{'type'} } . $val;
    $val .= '"' if $self->{'type'} eq 'symbol';

    $self->{'val'} =
      Kx::k2pscalar0( Kx::k( $self->{'kdb'}, "$list\[$i\]:$val" ) );
    return $self->{'val'};
}

sub FETCHSIZE {
    my $self = shift;
    my $list = $self->{'list'};

    $self->{'count'} = Kx::k2pscalar0( Kx::k( $self->{'kdb'}, "count $list" ) );
    return $self->{'count'};
}

#   STORESIZE this, count
#	   Sets the total number of items in the tied array associated with
#	   object this to be count. If this makes the array larger then
#	   class's mapping of "undef" should be returned for new positions.
#	   If the array becomes smaller then entries beyond count should be
#	   deleted.
#
sub STORESIZE {
    my $self  = shift;
    my $count = shift;
    my $list  = $self->{'list'};
    my $oldsz = $self->{'count'};

    my $q = '';
    if ( $count < $oldsz ) {

        # Truncate the list
        $q = "$list:$count#$list";
    }
    elsif ( $count > $oldsz ) {
        my $null = $NULL{ $self->{'type'} };
        my $diff = $count - $oldsz;
        $q = "$list:$list,$diff#$null";
    }
    else {
        # nothing to do
    }

    my $r = Kx::k( $self->{'kdb'}, $q );
    Kx::dor0($r);

    $self->{'count'} = $count;
}

sub EXTEND {
    my $self  = shift;
    my $count = shift;
    $self->STORESIZE($count);
}

sub CLEAR {
    my $self = shift;
    my $list = $self->{'list'};
    $self->{'count'} = 0;

    my $q = "$list:()";
    my $r = Kx::k( $self->{'kdb'}, $q );
    Kx::dor0($r);
}

sub UNTIE {
    carp &whowasi if $DEBUG;
    my $self = shift;
    Kx::DESTROY($self);
}

sub POP {
    my $self = shift;
    my $list = $self->{'list'};

    return undef if $self->{'count'} <= 0;

    $self->{'count'}--;

    # Get value
    my $q = "-1#$list";
    $self->{'val'} = Kx::k2parray0( Kx::k( $self->{'kdb'}, $q ) );

    # reduce list
    $q = "$list:-1_$list";
    my $r = Kx::k( $self->{'kdb'}, $q );
    Kx::dor0($r);

    return $self->{'val'}[0];
}

sub PUSH {
    my $self = shift;
    my @arr  = @_;
    my $list = $self->{'list'};
    my $cast = $CAST{ $self->{'type'} };

    my $issymbol = $self->{'type'} eq 'symbol';

    # Do N at a time
    while (@arr) {
        my $q = "$list:$list,(";
        for my $v ( splice( @arr, 0, 500 ) ) {
            $v = $cast . $v;
            $v .= '"' if $issymbol;
            $q .= "$v;";
        }
        chop($q);
        $q .= ')';
        my $r = Kx::k( $self->{'kdb'}, $q );
        Kx::dor0($r);
    }

    return $self->FETCHSIZE();
}

sub SHIFT {
    my $self = shift;
    my $list = $self->{'list'};

    return undef if $self->{'count'} <= 0;

    $self->{'count'}--;

    my $q = "1#$list";
    $self->{'val'} = Kx::k2parray0( Kx::k( $self->{'kdb'}, $q ) );
    $q = "$list:1_$list";
    my $r = Kx::k( $self->{'kdb'}, $q );
    Kx::dor0($r);
    return $self->{'val'}[0];
}

sub UNSHIFT {
    my $self = shift;
    my @arr  = @_;
    my $list = $self->{'list'};
    my $cast = $CAST{ $self->{'type'} };

    my $issymbol = $self->{'type'} eq 'symbol';

    # Do N at a time
    while (@arr) {
        my $q   = "$list:(";
        my $len = @arr;
        $len = 500 if $len > 500;
        for my $v ( splice( @arr, -$len ) ) {
            $v = $cast . $v;
            $v .= '"' if $issymbol;
            $q .= "$v;";
        }
        chop($q);
        $q .= "),$list";
        my $r = Kx::k( $self->{'kdb'}, $q );
        Kx::dor0($r);
    }

    return $self->FETCHSIZE();
}

#   SPLICE this, offset, length, LIST
#	   Perform the equivalent of "splice" on the array.
#
#	   offset is optional and defaults to zero, negative values count back
#	   from the end of the array.
#
#	   length is optional and defaults to rest of the array.
#
#	   LIST may be empty.
#
#	   Returns a list of the original length elements at offset.
sub SPLICE {
    my $self = shift;
    my $i    = shift || 0;
    my $len  = shift || $self->{'count'} - $i;
    my @arr  = @_;

    my $list  = $self->{'list'};
    my $count = $self->{'count'};

    # Sanity check on $i and $len
    return undef if abs($i) >= $count;
    return undef if $len <= 0;
    if ( $i < 0 ) {
        $len = abs($i) if $len > abs($i);    # Clamp length if too big
        $i = $count + $i + 1;
    }
    return undef if ( $len + $i ) > $count;

    my $q;

    # First get hold of the old data to return
    $q = "$list\[(til $len) + $i\]";
    my $aref = Kx::k2parray0( Kx::k( $self->{'kdb'}, $q ) );

    if (@arr) {

        # Now add the new stuff
        $q = "$list\[(til $len) + $i\]:(";
        my $cast = $CAST{ $self->{'type'} };

        my $issymbol = $self->{'type'} eq 'symbol';

        for ( my $j = 0 ; $j < $len && $j <= $#arr ; $j++ ) {
            my $v = $cast . $arr[$j];
            $v .= '"' if $issymbol;
            $q .= "$v;";
        }
        chop($q);
        $q .= ')';
        my $r = Kx::k( $self->{'kdb'}, $q );
        Kx::dor0($r);
    }
    else {
        # delete the slice. from 0 to $i to $j cut the list and join the
        # front and back bits back together
        my $j = $i + $len;
        $q = "$list:raze (0 $i $j\_$list)[0 2]";
        my $r = Kx::k( $self->{'kdb'}, $q );
        Kx::dor0($r);
    }
    return @$aref;
}

sub DELETE {
    my $self = shift;
    my $i    = shift;
    my $list = $self->{'list'};

    return undef if $i < 0;
    $self->EXTEND($i) if $i >= $self->{'count'};

    # A null value
    my $val = $NULL{ $self->{'type'} };

    $self->{'val'} =
      Kx::k2pscalar0( Kx::k( $self->{'kdb'}, "$list\[$i\]:$val" ) );
    return $self->{'val'};
}

sub EXISTS {
    my $self = shift;
    my $i    = shift;

    return 0 if $i < 0 || $i >= $self->{'count'};
    my $list = $self->{'list'};
    my $null = $NULL{ $self->{'type'} };
    return Kx::k2pscalar0( Kx::k( $self->{'kdb'}, "not $list\[$i\]=$null" ) );
}

package Kx::HASH;
#####################################################################
#                           K Hash package                          #
#####################################################################
$Kx::HASH::VERSION = '0.042';
=head1 Kx::HASH

You may wish to tie a Perl hash to a Kdb+ variable. Well, you can do
that as well. Try something like this:

    use Kx;

    my %config = (
            host=>"localhost",
            port=>2222,
            userpass=>'user:pass', # optional
            ktype=>'symbol',
            vtype=>'int',
            dict=>'x',
            create=>1
    );
    tie(%x, 'Kx::HASH', %config);
    
    print "Size of hash x is :". scalar %x ."\n";
    for(0..5) {
        $x{"a$_"} = $_;
    }
    
    %y = %x;
    
    for(0..5) {
        print $y{"a$_"}," " if exists $y{"a$_"};
    }
    print "\n";
    
    while(($k,$v) = each %x) {
        print "Key=>$k is $v\n";
    }
    untie(%x);

All the functions defined in perltie for hashs are included.

Note: ktype is a Kdb+ type as defined in Types below - it is the
'key' type for the hash. vtype is also defined in Types - it is the
value type. Only simple types are allowed at the moment.

=cut

use 5.008;
use strict;
use warnings;
use Carp;
sub whowasi { ( caller(1) )[3] . '()' }

sub DESTROY {
    carp &whowasi if $DEBUG;
    my $self = shift;
    dor0( $self->{'K'} ) if defined $self->{'K'};    # release memory
}

sub TIEHASH {
    carp &whowasi if $DEBUG;
    my $class = shift;
    my %opts  = @_;
    my $d;                                           # Dictionary

    return undef unless defined $opts{'dict'};

    my $name = 'default';
    $name = $opts{'name'} if defined $opts{'name'};

    my $ref = { 'name' => $name };
    if ( defined $opts{'host'} ) {
        $DB{$name}{'host'} = $opts{'host'};
    }
    if ( defined $opts{'port'} ) {
        $DB{$name}{'port'} = $opts{'port'};
    }
    if ( defined $opts{'check_for_errors'} ) {
        $DB{$name}{'check_for_errors'} = $opts{'check_for_errors'};
    }

    if ( defined $opts{'dict'} ) {
        $ref->{'dict'} = $opts{'dict'};
    }
    if ( defined $opts{'create'} ) {
        $ref->{'create'} = 1;
    }
    my $ktype = $opts{'ktype'} || 'symbol';
    my $vtype = $opts{'vtype'} || 'symbol';
    $ref->{'ktype'} = $ktype;
    $ref->{'vtype'} = $vtype;

    # Get hold of any previously defined connection handle
    if ( defined $DB{$name}{'kdb'} ) {
        $ref->{'kdb'} = $DB{$name}{'kdb'};    # no need for connect
        $DB{$name}{'count'}++;
    }
    else                                      # get connected a new
    {
        if ( defined $DB{$name}{'userpass'} ) {
            $ref->{'kdb'} = Kx::khpu(
                $DB{$name}{'host'},
                $DB{$name}{'port'},
                $DB{$name}{'userpass'}
            );
        }

        # host, port only
        else {
            $ref->{'kdb'} = Kx::khp( $DB{$name}{'host'}, $DB{$name}{'port'} );
        }
        unless ( $ref->{'kdb'} > 0 ) {
            undef $ref->{'kdb'};
            return undef;
        }
        $DB{$name}{'kdb'} = $ref->{'kdb'};
        $DB{$name}{'count'}++;
    }

    # OK check if the variable already exists. If not then create it
    my $var = Kx::k2parray0( Kx::k( $ref->{'kdb'}, '\v' ) );
    $d = $ref->{'dict'};
    if ( !grep( /^$d$/, @$var ) || defined $ref->{'create'} ) {

        # Need to create it.
        my $r = Kx::k( $ref->{'kdb'}, "$d:(`$ktype\$())!`$vtype\$()" );
        if ( $r == 0 ) {
            carp "Undefined K structure in TIEHASH\n";
            return undef;
        }
        if ( Kx::kType($r) < 0 ) {
            carp "K error ", Kx::k2pscalar($r), "\n";
            return undef;
        }
    }

    return bless $ref, $class;
}

sub FETCH {
    carp &whowasi if $DEBUG;
    my $self = shift;
    my $key  = shift;

    my $dict  = $self->{'dict'};
    my $ktype = $self->{'ktype'};

    # Cast key to right type
    $key = $CAST{$ktype} . $key;
    $key .= '"' if $ktype eq 'symbol';
    $self->{'val'} = Kx::k2pscalar0( Kx::k( $self->{'kdb'}, "$dict $key" ) );
    return $self->{'val'};
}

sub STORE {
    carp &whowasi if $DEBUG;
    my $self = shift;
    my $key  = shift;
    my $val  = shift;

    my $dict  = $self->{'dict'};
    my $ktype = $self->{'ktype'};
    my $vtype = $self->{'vtype'};

    # Cast key and value to right type
    if ( $ktype eq "symbol" ) {
        $key = '`$"' . $key . '"';
    }
    else {
        $key = $CAST{$ktype} . $key;
    }
    if ( $vtype eq "symbol" ) {
        $val = '`$"' . $val . '"';
    }
    else {
        $val = $CAST{$vtype} . $val;
    }
    my $r = Kx::k( $self->{'kdb'}, "$dict" . "[$key]:$val" );
    Kx::dor0($r);
    return;
}

sub DELETE {
    carp &whowasi if $DEBUG;
    my $self = shift;
    my $key  = shift;

    my $dict = $self->{'dict'};
    $self->{'K'} = Kx::k( $self->{'kdb'}, ".[`$dict;();_;$key]" );
    Kx::dor0( $self->{'K'} );
    return 1;
}

sub CLEAR {
    carp &whowasi if $DEBUG;
    my $self = shift;

    my $d     = $self->{'dict'};
    my $ktype = $self->{'ktype'};
    my $vtype = $self->{'vtype'};

    my $r = Kx::k( $self->{'kdb'}, "$d:(`$ktype\$())!`$vtype\$()" );
    Kx::dor0($r);
    return 1;
}

sub EXISTS {
    carp &whowasi if $DEBUG;
    my $self = shift;
    my $key  = shift;

    my $dict  = $self->{'dict'};
    my $ktype = $self->{'ktype'};

    # Cast key to right type
    $key = $CAST{$ktype} . $key;
    $key .= '"' if $ktype eq 'symbol';
    my $null = $NULL{ $self->{'vtype'} };
    $self->{'K'} = Kx::k( $self->{'kdb'}, "not $dict" . "[$key]=$null" );
    return Kx::k2pscalar0( $self->{'K'} );
}

sub FIRSTKEY {
    carp &whowasi if $DEBUG;
    my $self = shift;

    my $dict = $self->{'dict'};
    $self->{'i'}     = 0;
    $self->{'count'} = Kx::k2pscalar0( Kx::k( $self->{'kdb'}, "count $dict" ) );
    $self->{'K'}     = Kx::k( $self->{'kdb'}, "(key $dict)[0]" );
    return Kx::k2pscalar0( $self->{'K'} );
}

sub NEXTKEY {
    carp &whowasi if $DEBUG;
    my $self = shift;

    my $dict = $self->{'dict'};
    $self->{'i'}++;
    return undef if $self->{'i'} >= $self->{'count'};

    my $i = $self->{'i'};
    $self->{'K'} = Kx::k( $self->{'kdb'}, "(key $dict)[$i]" );
    return Kx::k2pscalar0( $self->{'K'} );
}

sub SCALAR {
    carp &whowasi if $DEBUG;
    my $self = shift;

    my $dict = $self->{'dict'};
    $self->{'K'} = Kx::k( $self->{'kdb'}, "count $dict" );
    return Kx::k2pscalar0( $self->{'K'} );
}

sub UNTIE {
    my $self = shift;
    Kx::DESTROY($self);
}

package Kx;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;

__END__

=head1 SEE ALSO

L<http://kx.com>

L<http://code.kx.com>

See the test code under the 't' directory of this module for more details
on how to call each method.

=head1 AUTHORS

=over 4

=item *

Mark Pfeiffer <markpf@mlp-consulting.com.au>

=item *

Stephan Loyd <stephanloyd9@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Mark Pfeiffer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

This code is not affiliated with KxSystems in anyway. It is just a simple
interface to their code. Any functionality that is of any use is due to
the hard work of the people at KxSystems.

This is Alpha code. Use at your own risk. It is availble only for testing
at the moment. It has not been fully tested. For example nulls, inf and
the like. Your kms may vary.

If this code is useful then please drop me a line and let me know. I
would also like to be acknowledged in any products you may make from
this. I get a bit of a buzz out of it.

The F<LICENSE> file in the package is the Perl 5 license.

=head1 BUGS

Plenty and to be expected. Please send me any bugs you find. Patches
are even better and will always be acknowledged.

Once the code has been tested for a while I'll move it to beta. Don't
hold your breath though.

All spelling mistakes are mine ;-)

=cut

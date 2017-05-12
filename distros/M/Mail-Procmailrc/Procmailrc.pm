## Scott Wiersdorf
## Created: Thu Jan 24 11:29:59 MST 2002
## $Id: Procmailrc.pm,v 1.12 2002/07/30 17:59:19 scottw Exp $

##################################
package Mail::Procmailrc;
##################################

use strict;
use Carp qw(carp);

use vars qw( $VERSION $Debug %RE );

$VERSION = '1.09';
$Debug   = 0;
%RE      = (
	    'flags'    => qr/^\s*:0/o,                   ## flags
	    'flagsm'   => qr/^\s*(:0.*)$/o,              ## flags match
	    'var'      => qr/^\s*[^#\$=]+=.*/o,          ## var
	    'varm'     => qr/^\s*([^#\$=]+=.*)$/o,       ## var match
	    'varmlq'   => qr/^[^\"]+=[^\"]*"[^\"]*$/so,  ## var multiline quote
	    'blklinem' => qr/^\s*\{\s*(.*?)\s*\}\s*$/o,  ## block line match
	    'blkopen'  => qr/^\s*\{/o,                   ## block open
	    'blkclose' => qr/^\s*\}/o,                   ## block close
	    'blank'    => qr/^\s*$/o,                    ## blank line
	    'cont'     => qr/\\$/o,                      ## continuation
	    'comt'     => qr/^\s*\#/o,                   ## comment
	    'comm'     => qr/^\s*(\#.*)$/o,              ## comment match
	    'condm'    => qr/^\s*(\*.*)$/o,              ## condition match
	   );

sub new {
    my $self = bless { }, shift;
    my $data = shift;

    $self->init($data);
    return $self;
}

sub init {
    my $self = shift;
    my $data = shift;

    ## initialize data array
    $self->rc([]);   ## our internal keeper of the data

    #########################################
    ## set parameters
    #########################################

    ## named parameters
    if( 'HASH' eq ref($data) ) {
	$self->read( $data->{'file'} );
	$self->level( $data->{'level'} );
	$self->parse( $data->{'data'} ) if $data->{'data'};
    }

    ## just a filename
    else {
	$self->read($data);
    }

    return 1;
}

sub read {
    my $self = shift;
    my $file = shift;

    ## reset file
    return unless $file = $self->file($file);
    return unless -f $file;

    ## FIXME: advisory lock here?
    open FILE, $file
      or do {
	  carp( "Error reading file '$file': $!\n" );
	  return;
      };

    ## FIXME: this is bad... Should pass in a typeglob instead...
    $self->parse( [<FILE>] );
    close FILE;
}

sub parse {
    my $self = shift;
    my $data = shift;  ## this may be a string or array reference
    my @data = ();     ## chunks to hand off to object creators

    ## state
    my %ST      = ( FILE     => 0,  0 => 'FILE',
		    VARIABLE => 1,  1 => 'VARIABLE',
		    RECIPE   => 2,  2 => 'RECIPE',
		    LITERAL  => 3,  3 => 'LITERAL',
		);
    my @state = ( $ST{FILE} );

    ## initialize our data
    $self->rc([]);

    ## make sure we're using an array reference
    if( 'ARRAY' eq ref($data) ) {
	chomp @$data;
    }
    else {
	## we don't know how to handle other kinds of refs here
	return if ref($data);

	## split the data (implicit chomping)
	$data = [split(/\n/, $data)];
    }

    ## this is the procmailrc parser
    my $line;
    while( defined ($line = shift @$data) ) {
	gubed( "LINE: $line" );

	## block line gets rewritten (but noted with $obj->blockline(1))
	if( $line =~ s/$RE{'blklinem'}/$1/ ) {
	    ## if $line is now an empty line (or whitespace only),
	    ## we'll take that into consideration in the blank line
	    ## case below
	    $self->blockline(1);
	}

	## found a recipe
	if( $line =~ s/$RE{'flagsm'}/$1/ ) {
	    unshift @$data, $line;
	    $self->push( Mail::Procmailrc::Recipe->new($data, {'level' => $self->level} ) );
	}

	## found a variable assignment
	elsif( $line =~ s/$RE{'varm'}/$1/ ) {
	    unshift @$data, $line;
	    $self->push( Mail::Procmailrc::Variable->new($data, {'level' => $self->level}) );
	}

	## a comment between chunks
	elsif( $line =~ /$RE{'comm'}/ ) {
	    $self->push( Mail::Procmailrc::Literal->new($line, {'level' => $self->level}) );
	}

	## completely blank line
	elsif( $line =~ /$RE{'blank'}/ ) {
	    ## if the next line is blank too...
	    if( defined $data->[0] && $data->[0] =~ /$RE{'blank'}/ ) {
		## skip blank lines (unless this line is a block line)
		next unless $self->blockline;
	    }
	    $self->push( Mail::Procmailrc::Literal->new($line, {'level' => $self->level}) );
	}

	## open block triggers special behavior for the object
	elsif( $line =~ /$RE{'blkopen'}/ ) {
	    $self->push( Mail::Procmailrc::Literal->new($line, {'level' => $self->level}) );
	    $self->level($self->level + 1);
	}

	## close block triggers special behavior for the object
	elsif( $line =~ /$RE{'blkclose'}/ ) {
	    $self->level($self->level - 1);
	    $self->push( Mail::Procmailrc::Literal->new($line, {'level' => $self->level}) );
	    last;
	}

	## something else
	else {
	    ## do nothing? Could push a literal here...
	}

	## bail if we only expected one line
	last if $self->blockline;
    }

    return 1;
}

## FIXME: should be checks here for array refs/lists
sub rc {
    my $self = shift;
    my $data = shift;

    return ( defined $data
	     ? $self->{RCDATA} = $data
	     : $self->{RCDATA} );
}

sub recipes {
    my $self = shift;
    return [ grep { $_->isa('Mail::Procmailrc::Recipe') } @{$self->rc} ];
}

sub variables {
    my $self = shift;
    return [ grep { $_->isa('Mail::Procmailrc::Variable') } @{$self->rc} ];
}

sub literals {
    my $self = shift;
    return [ grep { $_->isa('Mail::Procmailrc::Literal') } @{$self->rc} ];
}

sub push {
    my $self = shift;
    CORE::push @{$self->rc}, @_;
}

## FIXME: would be nice to do this w/o temporary arrays
sub delete {
    my $self  = shift;
    my $seek  = shift;
    my $found = 0;

    return unless $seek && ref($seek);

    my @tmp = ();
    for my $obj ( @{$self->rc} ) {
	CORE::push @tmp, $obj;
	next if $found;
	next unless $obj == $seek;
	pop @tmp;
	$found++;
    }
    $self->rc(\@tmp);
}

sub stringify {
    return $_[0]->dump;
}

sub dump {
    my $self = shift;
    my $output = '';
    my $sp     = ( defined $self->level ? $self->level * 2 : 0 );

    ## only one element in our list
    if( $self->blockline ) {
	$output .= (' ' x $sp) . "\{ " . $self->rc->[0]->stringify . ' }';
	$output =~ s/\{\s*\}/{ }/;  ## squeeze empties
    }

    ## dump our stack
    else {
	for my $elem ( @{$self->rc} ) {
	    next unless defined $elem;
	    $output .= $elem->dump;
	}
    }

    return $output;
}

sub flush {
    my $self = shift;
    my $file = shift;

    ## reset the file attribute
    $file = $self->file($file);

    ## flush the object to disk
    if( $file ) {
	open FILE, ">$file"
	  or do {
	      carp "Could not open '$file' for write: $!\n";
	      return;
	  };
    }

    ## no file, flush to stdout
    else {
	open FILE, ">&STDOUT" unless $file;
    }
    print FILE $self->dump;
    close FILE;

    return 1;
}

sub debug {
    my $self  = shift;
    my $debug = shift;

    return ( defined $debug ? $Debug = $debug : $Debug );
}

sub file {
    my $self = shift;
    my $file = shift;

    return ( defined $file ? $self->{File} = $file : $self->{File} );
}

sub level {
    my $self = shift;
    my $level = shift;

    return ( defined $level 
	     ? $self->{Level} = $level 
	     : ( defined $self->{Level}
		 ? $self->{Level}
		 : 0 ) );
}

sub blockline {
    my $self = shift;
    my $blockline = shift;

    return ( defined $blockline ? $self->{Blockline} = $blockline : $self->{Blockline} );
}

sub gubed {
    return unless $Debug;

    my $msg = shift;
    chomp $msg;
    print STDERR "$msg\n";
}

##################################
package Mail::Procmailrc::Literal;
##################################

sub new {
    my $self = bless { }, shift;
    my $data = shift;
    my $defs = shift;

    ## set defaults
    $self->defaults($defs) if ref $defs;

    ## FIXME: would be simple to make a super object and have literal,
    ## variable, and recipe inherit from it... Or recipe components
    ## inherit from it... I should be careful here and in documenting
    ## it so that I only mention the minimum necessary to keep a
    ## consistent interface.

    $self->literal($data);

    return $self;
}

sub defaults {
    my $self     = shift;
    my $defaults = shift;
    my $value    = shift;

    ## nada: return whole hashref
    unless( $defaults ) {
	return $self->{DEFAULTS};
    }

    ## no hashref: return element of hashref
    unless( ref($defaults) ) {
	return ( defined $self->{DEFAULTS}->{$defaults} 
		 ? ( defined $value 
		     ? $self->{DEFAULTS}->{$defaults} = $value
		     : $self->{DEFAULTS}->{$defaults} )
		 : undef );
    }

    ## hashref: assign hashref
    return $self->{DEFAULTS} = $defaults;
}

sub literal {
    my $self = shift;
    my $data = shift;

    ## clean data
    chomp $data       if $data;
    $data =~ s/^\s*// if $data;
    $data =~ s/\s*$// if $data;

    return ( defined $data ? 
	     $self->{DATA} = $data 
	     : ( $self->{DATA} ? $self->{DATA} : '' ) );
}

sub stringify {
    return $_[0]->literal;
}

sub dump {
    my $self = shift;
    my $sp   = ( defined $self->defaults('level') ? $self->defaults('level') * 2 : 0 );
    return (' ' x $sp) . $self->stringify . "\n";
}

##################################
package Mail::Procmailrc::Variable;
##################################
use Carp qw(carp);

## FIXME: handle comments on the assignment line

use vars qw($Debug); $Debug = 0;

sub new {
    my $self = bless { }, shift;
    my $data = shift;
    my $defs = shift;  ## defaults

    $self->defaults($defs) if $defs;
    $self->init($data);
    return $self;
}

sub defaults {
    my $self     = shift;
    my $defaults = shift;
    my $value    = shift;

    ## nada: return whole hashref
    unless( $defaults ) {
	return $self->{DEFAULTS};
    }

    ## no hashref: return element of hashref
    unless( ref($defaults) ) {
	return ( defined $self->{DEFAULTS}->{$defaults} 
		 ? ( defined $value 
		     ? $self->{DEFAULTS}->{$defaults} = $value
		     : $self->{DEFAULTS}->{$defaults} )
		 : undef );
    }

    ## hashref: assign hashref
    return $self->{DEFAULTS} = $defaults;
}

sub init {
    my $self = shift;
    my $data = shift;
    my $line;

    return unless defined $data;

    ## get a variable declaration
    $line .= shift @$data;

    ## check assignment
    unless( $line =~ /$Mail::Procmailrc::RE{'var'}/ ) {
	carp "Could not init: bad pattern in '$line'\n";
	return;
    }

    ## check for multiline quote
    if( $line =~ $Mail::Procmailrc::RE{'varmlq'} ) {
	while( @$data && $line =~ $Mail::Procmailrc::RE{'varmlq'} ) {
	    $line .= "\n";
	    $line .= shift @$data;
	}
    }

    else {
	## check for continuation
	while( $line =~ /$Mail::Procmailrc::RE{'cont'}/ ) {
	    $line .= "\n";
	    $line .= shift @$data;
	}
    }

    $self->variable($line);

    return 1;
}

sub lval {
    my $self = shift;
    my $data = shift;
    chomp $data if $data;

    return ( defined $data ? $self->{LVAL} = $data : $self->{LVAL} );
}

sub rval {
    my $self = shift;
    my $data = shift;
    chomp $data if $data;

    return ( defined $data ? $self->{RVAL} = $data : $self->{RVAL} );
}

sub variable {
    my $self = shift;
    my $data = shift;

    if( $data ) {
	chomp $data;
	my( $lval, $rval ) = split(/=/, $data, 2);
	$self->lval($lval);
	$self->rval($rval);
    }

    return join('=', $self->lval, $self->rval);
}

sub stringify {
    return $_[0]->variable;
}

sub dump {
    my $self = shift;
    my $sp   = ( defined $self->defaults('level') ? $self->defaults('level') * 2 : 0 );
    return (' ' x $sp) . $self->stringify . "\n";
}

## debug output
sub gubed {
    return unless $Debug;

    my $msg = shift;
    chomp $msg;
    print STDERR "$msg\n";
}

##################################
package Mail::Procmailrc::Recipe;
##################################

## FIXME: handle comments on the flags line

use Carp qw(carp);

sub new {
    my $self = bless { }, shift;
    my $data = shift;
    my $defs = shift;  ## defaults

    $self->defaults($defs) if $defs;
    $self->init($data);
    return $self;
}

sub defaults {
    my $self     = shift;
    my $defaults = shift;
    my $value    = shift;

    ## nada: return whole hashref
    unless( $defaults ) {
	return $self->{DEFAULTS};
    }

    ## no hashref: return element of hashref
    unless( ref($defaults) ) {
	return ( defined $self->{DEFAULTS}->{$defaults} 
		 ? ( defined $value 
		     ? $self->{DEFAULTS}->{$defaults} = $value
		     : $self->{DEFAULTS}->{$defaults} )
		 : undef );
    }

    ## hashref: assign hashref
    return $self->{DEFAULTS} = $defaults;
}

sub init {
    my $self = shift;
    my $data = shift;
    my $line;

    $self->{FLAGS}      = undef;
    $self->{INFO}       = undef;
    $self->{CONDITIONS} = undef;
    $self->{ACTION}     = undef;

    ## init members
    $self->flags('');
    $self->info([]);
    $self->conditions([]);
    $self->action('');

    return unless defined $data;

    if( 'ARRAY' eq ref($data) ) {
	chomp @$data;
    }
    else {
	## we don't know how to handle other kinds of refs here
	return if ref($data);

	## split the data (implicit chomping)
	$data = [split(/\n/, $data)];
    }

    ## required: FLAGS
  FLAGS: {
	$line = shift @$data;
	$line =~ s/^\s*//;
	unless( $line =~ /$Mail::Procmailrc::RE{'flags'}/ ) {
	    carp( "Not a recipe: $line\n" );
	    return;
	}
	$self->flags($line);
    }

    ## optional: INFO
  INFO: {
	## get a line
	$line = shift @$data;
	last INFO unless defined $line;
	$line =~ s/^\s*//;

	## comment/info
	if( $line =~ s/$Mail::Procmailrc::RE{'comm'}/$1/ ) {
	    push @{$self->info}, $line;
	    redo INFO;
	}

	## skip empty lines
	if( $line =~ /$Mail::Procmailrc::RE{'blank'}/ ) {
	    redo INFO;
	}

	## a non-empty, non-comment line. Maybe it's a condition...
	unshift @$data, $line;
    }

    ## optional: CONDITIONS
  CONDITIONS: {
	## get a line
	$line = shift @$data;
	last CONDITIONS unless defined $line;
	$line =~ s/^\s*//;

	## check for condition
	if( $line =~ s/$Mail::Procmailrc::RE{'condm'}/$1/ ) {
	    while( $line =~ /$Mail::Procmailrc::RE{'cont'}/ ) {
		$line .= "\n";         ## tack on the newline for quoted lines
		$line .= shift @$data;
	    }

	    push @{$self->conditions}, $line;
	    redo CONDITIONS;
	}

	## check for embedded comments and skip them
	if( $line =~ /$Mail::Procmailrc::RE{'comt'}/ ) {
	    redo CONDITIONS;
	}

	## check for empty lines and skip them
	if( $line =~ /$Mail::Procmailrc::RE{'blank'}/ ) {
	    redo CONDITIONS;
	}

	## non-empty, non-comment, non-condition. Maybe it's an action...
	unshift @$data, $line;
    }

    ## required: ACTION
  ACTION: {
	## get a line
	$line = shift @$data;
	last ACTION unless defined $line;
	$line =~ s/^\s*//;

	## if contains a '{' we pass it to Procmailrc
	if( $line =~ /$Mail::Procmailrc::RE{'blkopen'}/ ) {
	    unshift @$data, $line;
	    $self->action( Mail::Procmailrc->new( { 'data' => $data, 
						    'level' => $self->defaults('level') } ));
	}

	## this is a plain old action line
	else {
	    while( $line =~ /$Mail::Procmailrc::RE{'cont'}/ ) {
		$line .= "\n";
		$line .= shift @$data;
	    }
	    $self->action($line);
	}
    }

    return 1;
}

sub stringify {
    my $self   = shift;
    my $output = '';

    $output = $self->flags . "\n";

    $output   .= ( scalar(@{$self->info}) 
		   ? join( "\n", @{$self->info} ) . "\n"
		   : '' );
    $output   .= ( scalar(@{$self->conditions}) 
		   ? join( "\n", @{$self->conditions} ) . "\n"
		   : '' );
    $output   .= ( ref($self->action) 
		   ? $self->action->stringify
		   : $self->action );

    return $output;
}

sub dump {
    my $self   = shift;
    my $sp   = ( defined $self->defaults('level') ? $self->defaults('level') * 2 : 0 );
    my $output = '';

    ## flags
    $output = (' ' x $sp) . $self->flags . "\n";

    ## info
    $output   .= ( scalar(@{$self->info}) 
		   ? (' ' x $sp) . join( "\n" . (' ' x $sp), @{$self->info} ) . "\n"
		   : '' );

    ## conditions
    $output   .= ( scalar(@{$self->conditions}) 
		   ? (' ' x $sp) . join( "\n" . (' ' x $sp), @{$self->conditions} ) . "\n"
		   : '' );

    ## action
    $output   .= ( ref($self->action) 
		   ? $self->action->dump
		   : (' ' x $sp) . $self->action );

    ## kludge: we do this because sometimes the action object is
    ## dumped and other times it is just a string. When we nest a few
    ## of these, the newlines pile up and leave a lot of whitespace
    ## at the end of the recipe dump.
    chomp $output;
    $output .= "\n";

    return $output;
}

## data will be a scalar like :0B:
sub flags {
    my $self = shift;
    my $data = shift;

    return ( defined $data 
	     ? $self->{FLAGS} = Mail::Procmailrc::Literal->new($data)
	     : $self->{FLAGS}->stringify );
}

## data will be an array ref; if the data is a scalar, split it and
## make it a list ref
sub info {
    my $self = shift;
    my $data = shift;

    if( defined $data && !ref($data) ) {
	$data = [split(/\n/, $data)];
    }

    return ( defined $data ? $self->{INFO} = $data : $self->{INFO} );
}

## data will be an array ref upon which we push lines like '* 1^0 foo'
## FIXME: do we want to split scalars like we do for 'info'?
sub conditions {
    my $self = shift;
    my $data = shift;

    return ( defined $data ? $self->{CONDITIONS} = $data : $self->{CONDITIONS} );
}

## data will be scalar, possibly multiline; could be another rc object
sub action {
    my $self = shift;
    my $data = shift;
    chomp $data if $data && !ref($data);

    return ( defined $data ? $self->{ACTION} = $data : $self->{ACTION} );
}

1;
__END__

=head1 NAME

Mail::Procmailrc - An interface to Procmail recipe files

=head1 SYNOPSIS

  use Mail::Procmailrc;

  ## create a new procmailrc object and initialize it
  $pmrc = new Mail::Procmailrc("$HOME/.procmail/rc.spam");

  ## add a new variable
  $pmrc->push( new Mail::Procmailrc::Variable(["FOO=bar"]) );

  ## add a new recipe
  $recipe =<<'_RECIPE_';
  :0B:
  ## this will catch evil email messages
  * 1^0 xxx
  * 1^0 evil things
  * 1^0 porn and other wickedness
  * 1^0 all kinds of cursing
  * 1^0 lewdness, filth, etc\.
  /var/mail/evil
  _RECIPE_

  ## add this new recipe to our procmail rc file
  $pmrc->push( new Mail::Procmailrc::Recipe($recipe) );

  ## add another condition to our recipe (we shoulda left a scalar
  ## handle lying around, but this illustrates something useful)
  for my $obj ( @{$pmrc->rc} ) {
      ## find the recipe we just added by its 'info' string
      next unless $obj->stringify =~ /^\#\# this will catch evil email messages/m;

      ## we want to block emails about censorship, too ;o)
      push @{$obj->conditions}, '* 1^0 censor(ship|ing)?'
  }

  ## write this object to disk
  $pmrc->flush;

=head1 DESCRIPTION

B<Mail::Procmailrc> can parse B<procmail> recipe files and store the
contents in an object which can be later manipulated and saved (see
L</"CAVEATS"> and L</"BUGS/TODO"> for limitations and special
conditions).

You may also start with a fresh, empty B<Mail::Procmailrc> object,
populate it with recipes and/or variables and write it to file.

Recipes and variables are written to the file in the order they're
parsed and added.  If you want to re-order the recipes you may do so
by getting a handle on the variable or recipe list and ordering them
yourself.

The B<Mail::Procmailrc> object is primarily a list of B<procmail>
component objects (see below). When B<Mail::Procmailrc> parses a
B<procmail> rc file, it decides which lines are variable assignments,
which lines are comments, and which lines are recipes. It preserves
the order in which it encounters these B<procmail> components and
stores them as a list of objects in the main B<Mail::Procmailrc>
object.

=over 4

=item B<new>

Creates a new Mail::Procmailrc object.

Examples:

    ## 1. in memory object
    my $pmrc = new Mail::Procmailrc;

    ## 2. parses /etc/procmailrc
    my $pmrc = new Mail::Procmailrc("/etc/procmailrc");

    ## 3. parses /etc/procmailrc, makes backup
    my $pmrc = new Mail::Procmailrc("/etc/procmailrc");
    $pmrc->file("/etc/procmailrc.bak");
    $pmrc->flush;   ## create a backup

    $pmrc->file("/etc/procmailrc");  ## future flushes will go here

    ## 4. alternative syntax: filename specified in hashref
    my $pmrc = new Mail::Procmailrc( { 'file' => '/etc/procmailrc' } );

    ## 5. alternative syntax: scalar
    my $rc =<<_FOO_;
    :0B
    * 1^0 this is not spam
    /dev/null
    _FOO_
    my $pmrc = new Mail::Procmailrc( { 'data' => $rc } );

    ## 6. alternative syntax: array reference
    my $rc =<<'_RCFILE_';
    :0c:
    /var/mail/copy
    _RCFILE_
    my @rc = map { "$_\n" } split(/\n/, $rcfile);
    $pmrc = new Mail::Procmailrc( { 'data' => \@rc } );

=item B<read>

Sets the object's file attribute and parses the given file. If the
file is not readable, returns undef. Normally not invoked directly.

Example:

    ## set $pmrc->file and parse
    unless( $pmrc->read('/etc/procmailrc') ) {
        die "Could not parse '/etc/procmailrc!\n";
    }

=item B<parse>

Takes an array or string reference and populates the object with it.

Example:

    my $chunk =<<_RECIPE_;
    ## begin foo section
    TMPLOGFILE=\$LOGFILE
    TMPLOGABSTRACT=\$LOGABSTRACT
    TMPVERBOSE=\$VERBOSE
    
    LOGFILE=/var/log/foolog
    LOGABSTRACT=yes
    VERBOSE=no
    
    ## process the mail via foo
    :0fw
    |/usr/local/bin/foo -c /etc/mail/foo.conf
    
    LOGFILE=\$TMPLOGFILE
    LOGABSTRACT=\$TMPLOGABSTRACT
    VERBOSE=\$TMPVERBOSE
    ## end spamassassin vinstall (do not remove these comments)
    _RECIPE_

    ## make a new in-memory procmailrc file
    my $new_pmrc = new Mail::Procmailrc;
    $new_pmrc->parse($chunk);

    ## add this new procmailrc file to our existing procmailrc file
    $pmrc->push(@{$new_pmrc->rc});
    $pmrc->flush;

Alternatively, you can pass an array reference to B<parse>:

    $new_pmrc->parse([split("\n", $chunk)]);

=item B<rc>

Returns a list reference. Each item in the list is either a Variable,
Literal, or Recipe object. Items are returned in the order they were
originally parsed. You may assign to B<rc> and rewrite the
B<Mail::Procmailrc> object thereby.

Example:

    ## remove foo section from recipe file
    my @tmp_rc = ();
    my $foo_section = 0;
    for my $pm_obj ( @{$pmrc->rc} ) {
        if( $pm_obj->stringify =~ /^\#\# begin foo recipes/m ) {
            $foo_section = 1;
            next;
        }
        elsif( $pm_obj->stringify =~ /^\#\# end foo recipes/m ) {
            $foo_section = 0;
            next;
        }
        elsif( $foo_section ) {
            next;
        }
        push @tmp_rc, $rc_obj;
    }
    $pmrc->rc(\@tmp_rc);
    $pmrc->flush;

=item B<recipes>

Returns a listref of recipes in this object.

=item B<variables>

Returns a listref of variables in this object.

=item B<literals>

Returns a listref of literals in this object.

=item B<push>

Pushes the dat(a|um) onto this object's internal object list. If the
object being pushed is another Mail::Procmailrc object, that object's
B<rc> method is invoked first and the results are pushed.

Example:

    my $rc_objs = $old_pmrc->rc;
    $pmrc->push( @$rc_objs );

=item B<delete>

Deletes an object from the main Mail::Procmailrc object:

    for my $obj ( @{$pmrc->rc} ) {
        next unless $obj->isa('Mail::Procmailrc::Recipe');

        ## I lost all my enemies when I switched to the Perl Artistic License...
        next unless $obj->info->[0] =~ /^\#\# block email from enemies/;
        $pmrc->delete($obj);
        last;
    }

=item B<file>

Returns the path where this object will write when B<flush> is
invoked. If B<file> is given an argument, the object's internal
I<file> attribute is set to this path.

=item B<flush>

Writes the procmail object to disk in the file specified by the
B<file> attribute. If the B<file> attribute is not set, B<flush>
writes to STDOUT. If a filename is given as an argument, it is set as
the objects B<file> attribute.

Examples:

    ## 1. flushes to whatever $pmrc->file is set to (STDOUT if file is unset)
    $pmrc->flush;

    ## 2. flushes to a specific file; future flushes will also go here
    $pmrc->flush('/backup/etc/procmailrc');

=item B<stringify>

Returns the object in string representation.

=item B<dump>

Like B<stringify> but with nicer formatting (indentation, newlines,
etc.). Suitable for inclusion in procmail rc files.

=back

=head1 Mail::Procmailrc::Variable Objects

B<Mail::Procmailrc::Variable> objects are easy to create and use.
Normally, the B<Variable> constructor is invoked by
B<Mail::Procmailrc> during parsing. If you are creating or modifying
an existing B<procmail> rc file, you might do something like this:

    my $var = new Mail::Procmailrc::Variable(["VERBOSE=off"]);

or you might wish to do it another way:

    my $var = new Mail::Procmailrc::Variable;
    $var->lval('VERBOSE');
    $var->rval('off');

You may get a handle on all B<Variable> objects in an rc file with
the B<variables> method:

    ## change to verbose mode
    for my $var ( @{$pmrc->variables} ) {
        next unless $var->lval eq 'VERBOSE';
        $var->rval('yes');
        last;
    }

=head2 Mail::Procmailrc::Variable Methods

=over 4

=item B<variable([$string])>

I<$string>, if present, is split on the first '='. The left half is
assigned to B<lval> and the right half to B<rval>. If I<$string> is
false, B<lval> and B<rval> are concatenated with '=' and returned as
a single string.

=item B<lval([$val])>

Returns the current lvalue of the variable assignment, optionally
setting it if I<$val> is present.

=item B<rval([$val])>

Returns the current rvalue of the variable assignment, optionally
setting it if I<$val> is present.

=item B<stringify>

Returns the output of B<variable>. Provides a consistent interface to
all Mail::Procmailrc::* subclasses.

=item B<dump>

Returns the output of B<stringify> with a trailing newline. Suitable
for inserting into a B<procmail> rc file.

=item B<defaults([\%defaults [, $elem]])>

Returns some internal object settings, currently not very useful or
interesting except when parsing deeply nested recipes. Included here
for completeness.

=item B<init(\@data)>

Normally invoked by the constructor (B<new>), but may be used to
re-initialize an object.

=back

=head1 Mail::Procmailrc::Literal Objects

B<Mail::Procmailrc::Literal> objects are even easier to create and
use than B<Variable> objects. A B<Mail::Procmailrc::Literal> is simply
a I<string> with a few methods wrapped around it for convenient
printing.

You may get a handle on all B<Literal> objects in an rc file with the
B<literals> method:

    ## change a comment in the rc file
    for my $lit ( @{$pmrc->literals} ) {
        next unless $lit->literal =~ /## spam follows/i;
        $lit->literal('## this is a nice spam recipe');
        last;
    }

Here is how to create a new literal:

   ## create a new literal
   my $lit = new Mail::Procmailrc::Literal('## this file is for filtering spam');

   ## same as above
   my $lit = new Mail::Procmailrc::Literal;
   $lit->literal('## this file is for filtering spam');

   ## print it
   $lit->dump;

=head2 Mail::Procmailrc::Literal Methods

=over 4

=item B<literal([$string])>

Get or set the literal object contents.

=item B<dump>

Dump the contents of the object with a trailing newline.

=back

=head1 Mail::Procmailrc::Recipe Objects

A recipe object is made up of a flags object, zero or more literal
(comments or vertical whitespace) objects, zero or more condition
objects, and an action object. A B<Mail::Procmailrc::Recipe> object
is made of four parts:

=over 4

=item * flags (required)

=item * info/comment (optional)

=item * conditions (optional)

=item * action (required)

=back

Normally, the B<Recipe> object is created automatically during
parsing. However, if you are constructing a new rc file or want to
modify an existing procmailrc file, you will need to know a little
about the B<Recipe> object.

To create a recipe object from a string, you may do something like
this:

    $recipe =<<'_RECIPE_';
    :0B:
    ## block indecent emails
    * 1^0 people talking dirty
    * 1^0 dirty persian poetry
    * 1^0 dirty pictures
    * 1^0 xxx
    /dev/null
    _RECIPE_

    $recipe_obj = new Mail::Procmailrc::Recipe($recipe);

or the more obtuse (if you happen to already have an array or
reference):

    $recipe_obj = new Mail::Procmailrc::Recipe([split("\n", $recipe)]);

The entire recipe in I<$recipe> is now contained in the
I<$recipe_obj>. You could also piece together an object part by part:

    $recipe_obj = new Mail::Procmailrc::Recipe;
    $recipe_obj->flags(':0B');
    $recipe_obj->info([q(## block indecent emails)]);
    $recipe_obj->conditions([q(* 1^0 people talking dirty),
			     q(* 1^0 dirty persian poetry),
			     q(* 1^0 dirty pictures),
			     q(* 1^0 xxx),]);
    $recipe_obj->action('/dev/null');

You can get a handle on all recipes in an rc file with the B<recipes> method:

    my $conditions;
    for my $recipe ( @{$pmrc->recipes} ) {
        next unless $recipe->info->[0] =~ /^\s*\#\# this recipe is for spam/io;
        $conditions = $recipe->conditions;
        last;
    }
    push @$conditions, '* 1^0 this is not SPAM';  ## add another condition
    $pmrc->flush;  ## write out to file

=head2 Important Note about I<info>

The B<info> method of the B<Recipe> object is really just a procmail
comment (or B<literal> elsewhere in this document), but because it
appears between the B<flags> line (e.g., ':0fw') and the conditions
(e.g., * 1^0 foo), it becomes part of the recipe itself. This is
terribly convenient usage because it allows you to "index" your
recipes and find them later.

=head1 EXAMPLES

The F<eg> directory in the B<Mail::Procmailrc> distribution contains
at least one useful program illustrating the several uses of this
module. Other examples may appear here in future releases as well as
the F<eg> directory of the distribution.

=head1 CAVEATS

Parsing is I<lossy> in two senses. Some formatting and stray lines
may be lost. Also, array references fed to constructors will not be
returned intact (i.e., data will be shifted out of them).

=head1 BUGS/TODO

Please let the author/maintainer know if you find any bugs (providing
a regression test would also be helpful; see the testing format in
the 't' directory).

=over 4

=item *

We can't parse old-style "counting" syntax (before v2.90, 1993/07/01):

    :2:
    ^Subject:.*foo
    From:.*foo@bar\.com
    /tmp/eli/foo

Thanks to <eli@panix.com> (8 Oct 2002) for finding this bug.

=item *

We don't use any advisory locking on the B<procmail> rc files.  This
wouldn't be hard to fix, but I'm not sure it is needed.

=item *

We suck in the entire procmailrc file into memory. This could be done
more efficiently with a typeglob and reading the file line by line.

=item *

Comments on the flags line (e.g., ":0B     ## parse body") or on an
assignment line (e.g., "VAR=FOO   ## make FOO be known") are quietly
dropped when the rc file is parsed and they are not replaced when the
file is rewritten. If you want to keep comments around, put them on
a separate line.

=item * 

We don't recursively parse file INCLUDE directives. This could be
construed as a safety feature. The INCLUDE directives will show up,
however, as B<Variable> objects, so you could provide the recursion
pretty easily yourself.

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item 5 Feb 2003

Erwin Lansing (erwin@lansing.dk) for 5.00503 patch and doc typo.
Danke!

=back

=head1 COPYRIGHT

Copyright 2002 Scott Wiersdorf.

This library is free software; you can redistribute it and/or modify
it under the terms of the Perl Artistic License.

=head1 AUTHOR

Scott Wiersdorf <scott@perlcode.org>

=head1 SEE ALSO

L<procmail>, L<procmailrc(5)>, L<procmailex(5)>, L<procmailsc(5)>

=cut

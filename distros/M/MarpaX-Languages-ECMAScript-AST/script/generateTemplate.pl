#!env perl
use strict;
use warnings FATAL => 'all';
use MarpaX::Languages::ECMAScript::AST;
use File::Spec;
use File::Basename qw/dirname/;
use Cwd qw/abs_path cwd/;
use Carp qw/croak/;
use POSIX qw/EXIT_SUCCESS EXIT_FAILURE/;

# -------------------------------
# Generation of grammar templates
# -------------------------------
my @COPYARGV = @ARGV;
my $grammarName = shift || '';
if (! $grammarName) {
  print STDERR <<USAGE;
Usage  : $^X $0 grammarName

Example: $^X $0 ECMA-262-5
USAGE
  exit(EXIT_FAILURE);
}

#
# We generate templates as a perl class based on the G1 grammar. Note that we MUST be
# in the directory just upper than script/ . We use Cwd and $0 and verify that
# Cwd is the dirname of the dirname of $0.
#
my $cwd = File::Spec->canonpath(abs_path(cwd()));
my $parentDir = File::Spec->canonpath(abs_path(File::Spec->catdir(dirname($0), File::Spec->updir)));
#
# Note: we assume filenames are not bizarre, i.e. no need of Unicode::CaseFold
#
my $isSameDir = File::Spec->case_tolerant() ? (lc($cwd) eq lc($parentDir)) : ($cwd eq $parentDir);
if (! $isSameDir) {
    die "Please execute this script in directory $parentDir";
}

my $ecmaAst = MarpaX::Languages::ECMAScript::AST->new(grammarName => $grammarName);
my $descHashp = $ecmaAst->describe();
my $g1p = $ecmaAst->describe->{G1};
#
# Get all LHS
#
my %lhs = ();
map {$lhs{$g1p->{$_}->[0]}++} keys %{$g1p};
#
# Generate Template.pm
#
my $grammarAlias = $ecmaAst->grammarAlias;
my $file = File::Spec->catfile($parentDir, 'lib', 'MarpaX', 'Languages', 'ECMAScript', 'AST', 'Grammar', $grammarAlias, 'Template.pm');
if (! open(FILE, '>', $file)) {
    die "Cannot open $file, $!";
}
#
# We search for the LHS '[:start]'. The real starting point
# will be its LHS
#
my $startRuleId = undef;
foreach (keys %{$g1p}) {
    my $ruleId = $_;
    my $rulesp = $g1p->{$ruleId};
    my ($lhs, @rhs) = @{$rulesp};
    if ($lhs eq '[:start]') {
	$startRuleId = $ruleId;
    }
}
if (! defined($startRuleId)) {
    croak 'Cannot find :start';
}

print "Generating $file\n";
print FILE <<HEADER;
#
# This is a generated file using the command:
# $^X $0 @COPYARGV
#
use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::ECMAScript::AST::Grammar::${grammarAlias}::Template;

# ABSTRACT: Template for ${grammarAlias} transpilation using an AST

HEADER
#
# The fixed stuff: new(), lexeme(), indent(), transpile()
#
print FILE do {local $/; <DATA>};
foreach (sort {$a <=> $b} keys %{$g1p}) {
    my $ruleId = $_;
    my $rulesp = $g1p->{$ruleId};
    my ($lhs, @rhs) = @{$rulesp};
    my $rhsJoined = join(', ', map {"'$_'"} @rhs);
    my $g1Callback = '$self->{_g1Callback}';
    my $g1CallbackArgs = '$self->{_g1CallbackArgs}';
    print FILE "

=head2 G1_$ruleId(\$self, \$value, \$index)

Transpilation of G1 rule No $ruleId, i.e. $lhs ::= @rhs

\$value is the value of RHS No \$index (starting at 0).

=cut

sub G1_$ruleId {
    my (\$self, \$value, \$index) = \@_;

    my \$rc = '';

    if (&{$g1Callback}(\@{$g1CallbackArgs}, \\\$rc, $ruleId, \$value, \$index, '$lhs', $rhsJoined)) {
";
    foreach (0..$#rhs) {
        printf FILE "        %sif (\$index == $_) {\n", $_ > 0 ? 'els' : '';
	if (exists($lhs{$rhs[$_]})) {
            #print FILE "        my \$method$_ = defined(\$value->[$_]) ? \"G1_\$value->[$_]->{ruleId}\" : undef;\n";
            #print FILE "        my \$value$_ = (defined(\$method$_) ? (\$indent . \$self->\$method$_(\$value->[$_]->{values})) : '');\n";
	    #push(@value, "\$value$_");
	} else {
            print FILE <<DOLEXEME;
            \$rc = \$self->lexeme('$rhs[$_]', $ruleId, \$value, $_, '$lhs', $rhsJoined);
DOLEXEME
	}
        print FILE "        }\n";
    }
    print FILE "    }\n";
    print FILE "\n";
    print FILE "    return \$rc;\n";
    print FILE "}\n";
}
print FILE "\n1;\n";

if (! close(FILE)) {
    warn "Cannot close $file, $!";
}
exit(EXIT_SUCCESS);

__DATA__

# VERSION

=head1 DESCRIPTION

Generated generic template.

=head1 SUBROUTINES/METHODS

=head2 new($class, $optionsp)

Instantiate a new object. Takes as optional argument a reference to a hash that may contain the following key/values:

=over

=item g1Callback

G1 callback (CODE ref).

=item g1CallbackArgs

G1 callback arguments (ARRAY ref). The g1 callback is called like: &$g1Callback(@{$g1CallbackArgs}, \$rc, $ruleId, $value, $index, $lhs, @rhs), where $value is the AST parse tree value of RHS No $index of this G1 rule number $ruleId, whose full definition is $lhs ::= @rhs. If the callback is defined, this will always be executed first, and it must return a true value putting its eventual result in $rc. Only when it returns true, lexemes are processed.

=item lexemeCallback

lexeme callback (CODE ref).

=item lexemeCallbackArgs

Lexeme callback arguments (ARRAY ref). The lexeme callback is called like: &$lexemeCallback(@{$lexemeCallbackArgs}, \$rc, $name, $ruleId, $value, $index, $lhs, @rhs), where $value is the AST parse tree value of RHS No $index of this G1 rule number $ruleId, whose full definition is $lhs ::= @rhs. The RHS being a lexeme, $name contains the lexeme's name. If the callback is defined, this will always be executed first, and it must return a true value putting its result in $rc, otherwise default behaviour applies: return the lexeme value as-is.

=back

=cut

sub new {
    my ($class, $optionsp) = @_;

    $optionsp //= {};

    my $self = {
                _nindent            => 0,
                _g1Callback         => exists($optionsp->{g1Callback})         ? $optionsp->{g1Callback}         : sub { return 1; },
                _g1CallbackArgs     => exists($optionsp->{g1CallbackArgs})     ? $optionsp->{g1CallbackArgs}     : [],
                _lexemeCallback     => exists($optionsp->{lexemeCallback})     ? $optionsp->{lexemeCallback}     : sub { return 0; },
                _lexemeCallbackArgs => exists($optionsp->{lexemeCallbackArgs}) ? $optionsp->{lexemeCallbackArgs} : []
               };
    bless($self, $class);
    return $self;
}

=head2 lexeme($self, $value)

Returns the characters of lexeme inside $value, that is an array reference. C.f. grammar default lexeme action.

=cut

sub lexeme {
    my $self = shift;

    my $rc = '';

    if (! &{$self->{_lexemeCallback}}(@{$self->{_lexemeCallbackArgs}}, \$rc, @_)) {

        # my ($name, $ruleId, $value, $index, $lhs, @rhs) = @_;

        my $lexeme = $_[2]->[2];
        if    ($lexeme eq ';') { $rc = " ;\n" . $self->indent();  }
        elsif ($lexeme eq '{') { $rc = " {\n" . $self->indent(1); }
        elsif ($lexeme eq '}') { $rc = "\n"  . $self->indent(-1) . " }\n" . $self->indent();}
        else                   { $rc = " $lexeme"; }
      }

    return $rc;
}

=head2 indent($self, $inc)

Returns indentation, i.e. two spaces times current number of indentations. Optional $inc is used to change the number of indentations.

=cut

sub indent {
    my ($self, $inc) = @_;

    if (defined($inc)) {
	$self->{_nindent} += $inc;
    }

    return '  ' x $self->{_nindent};
}

=head2 transpile($self, $ast)

Tranpiles the $ast AST, that is the parse tree value from Marpa.

=cut

sub transpile {
    my ($self, $ast) = @_;

    my @worklist = ($ast);
    my $transpile = '';
    do {
	my $obj = shift(@worklist);
	if (ref($obj) eq 'HASH') {
	    my $g1 = 'G1_' . $obj->{ruleId};
	    # print STDERR "==> @{$obj->{values}}\n";
	    foreach (reverse 0..$#{$obj->{values}}) {
		my $value = $obj->{values}->[$_];
		if (ref($value) eq 'HASH') {
		    # print STDERR "Unshift $value\n";
		    unshift(@worklist, $value);
		} else {
		    # print STDERR "Unshift [ $g1, $value, $_ ]\n";
		    unshift(@worklist, [ $g1, $value, $_ ]);
		}
	    }
	} else {
	    my ($curMethod, $value, $index) = @{$obj};
	    # print STDERR "==> Calling $curMethod($value, $index)\n";
	    $transpile .= $self->$curMethod($value, $index);
	    # print STDERR "==> $transpile\n";
	}
    } while (@worklist);

    return $transpile;

#    my ($ruleId, $value) = ($ast->{ruleId}, $ast->{values});
#    my $method = "G1_$ruleId";
#    return $self->$method($value);
}

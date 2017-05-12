#! perl

package main;

our $cfg;

package EB::Shell::Base;

# ----------------------------------------------------------------------
# Shell::Base - A generic class to build line-oriented command interpreters.
# ----------------------------------------------------------------------
# Copyright (C) 2003 darren chamberlain <darren@cpan.org>
#
# This module is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
# ----------------------------------------------------------------------
#
# Modified for use by EekBoek by Johan Vromans.

use strict;

use EB;

use Text::ParseWords qw(shellwords);

# ----------------------------------------------------------------------
# new(\%args)
#
# Basic constructor.
#
# new() calls initialization methods:
#
#   - init_rl
#
#     o Initializes the Term::ReadLine instance
#
#   - init_help
#
#     o Initializes the list of help methods
#
#   - init_completions
#
#     o Initializes the list of tab-completable commands
#
#   - init
#
#     o Subclass-specific intializations.
#
# ----------------------------------------------------------------------
sub new {
    my $class = shift;
    $class = ref($class) || $class; # make it work with derived classes - jv
    my $args  = UNIVERSAL::isa($_[0], 'HASH') ? shift : { @_ };

    my $self  = bless {
        COMPLETIONS => undef,           # tab completion
        HELPS       => undef,           # help methods
        HISTFILE    => undef,           # history file
        PROMPT      => "eb> ",          # default prompt
        TERM        => undef,           # Term::ReadLine instance
	RL_DEBUG    => $cfg->val(qw(readline debug), 0),
    } => $class;

    $self->init_cm($args);
    $self->init_rl($args);
    $self->init_completions($args);
    $self->init_help($args);
    $self->init($args);

    return $self;
}

# ----------------------------------------------------------------------
# init_km(\%args)
#
# Initialize command name maps for translation.
# ----------------------------------------------------------------------
sub init_cm {
    my ($self, $args) = @_;

    # See EB::Utils for __XN, __xt and N__ .
    my %cm = map { __XN($_) => __xt($_) }
	# Opening.
	N__("cmd:adm_balans"),
	N__("cmd:adm_balanstotaal"),
	N__("cmd:adm_begindatum"),
	N__("cmd:adm_boekjaarcode"),
	N__("cmd:adm_btwperiode"),
	N__("cmd:adm_naam"),
	N__("cmd:adm_open"),
	N__("cmd:adm_relatie"),

	# Globale settings.
	N__("cmd:boekjaar"),

	# Rapporten.
	N__("cmd:balans"),
	N__("cmd:btwaangifte"),
	N__("cmd:crediteuren"),
	N__("cmd:debiteuren"),
	N__("cmd:grootboek"),
	N__("cmd:journaal"),
	N__("cmd:openstaand"),
	N__("cmd:proefensaldibalans"),
	N__("cmd:result"),

	# Informatie.
	N__("cmd:dagboeken"),
	N__("cmd:database"),
	N__("cmd:periodes"),
	N__("cmd:rapporten"),

	# Bewerkingen.
	N__("cmd:export"),
	N__("cmd:import"),
	N__("cmd:jaareinde"),
	N__("cmd:relatie"),
	N__("cmd:schema"),
	N__("cmd:toon"),
	N__("cmd:verwijder"),

	# Diversen.
	N__("cmd:include"),
	N__("cmd:sql"),
	;

    $self->{cm} = \%cm;
}

# ----------------------------------------------------------------------
# init_rl(\%args)
#
# Initialize Term::ReadLine.  Subclasses can override this method if
# readline support is not needed or wanted.
# ----------------------------------------------------------------------
sub init_rl {
    my ($self, $args) = @_;
    my ($term, $attr);

    $ENV{PERL_READLINE_NOWARN} = 1 unless $self->{RL_DEBUG};
    require Term::ReadLine;
    warn("\%Trying: ReadLine (", $ENV{PERL_RL}||"default", ")\n") if $self->{RL_DEBUG};
    $term = Term::ReadLine->new(ref $self);
    warn("\%Using: ", $term->ReadLine, "\n") if $self->{RL_DEBUG};
    $self->term($term);

    # Setup default tab-completion function.
    # Note that this will be overridden by EB::Shell->new.
    $attr = $term->Attribs;
    $attr->{completion_function} = sub { $self->complete(@_) };

    if (my $histfile = $args->{ HISTFILE }) {
	# Should use $term->Features->{addhistory} .
        $self->histfile($histfile);
	if ( $term->can("ReadHistory") ) {
	    $term->ReadHistory($histfile);
	}
	elsif ( open( my $fd, '<:encoding(utf8)', $histfile ) ) {
	    $self->{_history} = [];
	    while ( <$fd> ) {
		chomp;
		$term->addhistory($_);
		push( @{ $self->{_history} }, $_, "\n" );
	    }
	    close($fd);
	}
    }

    return $self;
}

# ----------------------------------------------------------------------
# init_help()
#
# Initializes the internal HELPS list, which is a list of all the
# help_foo methods defined within the current class, and all the
# classes from which the current class inherits from.
# ----------------------------------------------------------------------
sub init_help {
    my $self = shift;
    my $class = ref $self || $self;
    my %uniq = ();

    no strict qw(refs);
    $self->helps(
        grep { ++$uniq{$_} == 1 }
        map { s/^help_//; $self->{cm}->{$_}||$_ }
        grep /^help_/,
        map({ %{"$_\::"} } @{"$class\::ISA"}),
        keys  %{"$class\::"});
}

sub _xtr {
    my ( $self, $t ) = @_;
    (my $pfx, $t) = ( $1, $2 ) if $t =~ /^(.*):(.*)/;
    keys( %{$self->{cm}} );			# reset iteration
    while ( my ($k, $v) = each %{$self->{cm}} ) {
	next unless $t eq $v;
	return $1 if $k =~ /^tg_(.*)/;
	return $k;
    }
    undef;
}

# ----------------------------------------------------------------------
# init_completions()
#
# Initializes the internal COMPLETIONS list, which is used by the 
# complete method, which is, in turn, used by Term::ReadLine to
# do tab-compleion.
# ----------------------------------------------------------------------
sub init_completions {
    my $self = shift;
    my $class = ref $self || $self;
    my %uniq = ();

    no strict qw(refs);
    $self->completions(
        sort 
        "help",
        grep { ++$uniq{$_} == 1 }
        map { s/^(do|pp)_//; $self->{cm}->{$_}||$_ }
        grep /^(do|pp)_/,
        map({ %{"$_\::"} } @{"$class\::ISA"}),
        keys  %{"$class\::"});
}

# ----------------------------------------------------------------------
# init(\%args)
#
# Basic init method; subclasses can override this as needed.  This is
# the place to do any subclass-specific initialization.
#
# Command completion is initialized here, so subclasses should call
# $self->SUPER::init(@_) within overridden init methods if they want
# this completion to be setup.
# ----------------------------------------------------------------------
sub init {
    my ($self, $args) = @_;

    return $self;
}

# ----------------------------------------------------------------------
# run()
#
# run is the main() of the interpreter.  Its duties are:
#
#   - Get a line of input, via $self->term->readline.
#     This begins the run loop.
#
#     o Pass this line to $self->parseline for splitting into
#       (command_name, arguments)
#
#     o Check contents of command_name; there are a few special
#       cases:
#
#         + If the line is a help line, then call $self->help(@args)
#
#         + If the line is a quit line, then return with $self->quit()
#
#         + Otherwise, attempt to invoke $self->do_$command_name
#
#     o The output from whichever of the above is chosen will be
#       be printed via $self->print() if defined.
#
#     o The prompt is reset, and control returns to the top of
#       the run loop.
# ----------------------------------------------------------------------
sub run {
    my $self = shift;

    my $prompt = $self->prompt;
    my $anyfail;

    while (defined (my $line = $self->readline($prompt))) {
        my (@args, $cmd, $output);

        ($cmd, @args) = $self->parseline($line);

	# If there's a quoting mistake, parseline returns nothing.
	if ( $line =~ /\S/ && $cmd !~ /\S/ ) {
	    warn("?"._T("Fout in de invoerregel. Controleer de \" en ' tekens.")."\n");
	    next;
	}

        if (! length($cmd)) {
            next;
        }
        elsif ( $cmd =~ /^\s*(help|\?)/i ) {
            $output = $self->help(@args);
        }
        elsif ( $cmd =~ /^\s*(exit|quit|logout)/i ) {
            return $self->quit($anyfail?1:0);
        }
        else {
	    my $meth = "pp_".lc($self->_xtr("cmd:$cmd")||$cmd);
	    if ( $self->can($meth) ) {
		eval {
		    ($cmd, @args) = $self->$meth($cmd, @args);
		};
		if ($@) {
		    my $err = $@;
		    chomp $err;
		    warn "?$err\n";
		    next;
		}
	    }
	    $meth = "do_".lc($self->_xtr("cmd:".lc($cmd))||$cmd);
	    $meth =~ s/\s+/_/g;
	    if ( $self->can($meth) ) {
		eval {
		    # Check warnings for ? (errors).
		    my $fail = 0;
		    local $SIG{__WARN__} = sub {
			$fail++ if $_[0] =~ /^\?/;
			warn(@_);
		    };
		    $output = $self->$meth(@args);
		    # Throw error if errors detected.
		    die(bless {}, 'FatalError') if $fail && $self->{errexit};
		};
		if ( !$@ && $self->{errexit} && $output =~ /^\?/m ) {
		    eval { die($output) };
		}
		if ($@) {
		    $anyfail++;
		    unless ( UNIVERSAL::isa($@, 'FatalError') ) {
			my $err = $@;
			chomp $err;
			# jv                warn "$output ($err)\n";
			warn "?$err\n";
		    }
		    if ( $self->{errexit} ) {
			warn("?"._T(" ****** Afgebroken wegens fouten in de invoer ******")."\n");
			return $self->quit(1);
		    }
		}
	    }
	    else {
		warn("?".__x("Onbekende opdracht \"{cmd}\".\n\"help\" geeft een lijst van mogelijke opdrachten.", cmd => $cmd)."\n");
		undef($output);
		return $self->quit(1) if $self->{errexit};
	    }
        }

	# Suppress the newline if there's nothing to print.
	if ( defined $output ) {
	    $output =~ s/\n*$//;
	    chomp $output;
	    $self->print("$output\n") if $output;
	}

	# Make sure we're not in a pending transaction.
	if ( $::dbh->in_transaction ) {
	    warn("?INTERNAL ERROR: Command failed but did not rollback.\n");
	    $::dbh->rollback;
	}

        # In case someone modified the prompt, we recollect it before
        # displaying it.
        $prompt = $self->prompt();
    }

    $self->quit($anyfail?1:0);
}

# ----------------------------------------------------------------------
# readline()
#
# Calls readline on the internal Term::ReadLine instance.  Provided
# as a separate method within Shell::Base so that subclasses which
# do not want to use Term::ReadLine don't have to.
# ----------------------------------------------------------------------
sub __orig_readline {
    my ($self, $prompt) = @_;
    return $self->term->readline($prompt);
}

sub readline {
    my ($self, $prompt) = @_;
    my $line = $self->term->readline($prompt);
    push( @{ $self->{_history} }, $line."\n" ) if $line =~ /\S/;
    return $line;
}

# ----------------------------------------------------------------------
# print(@data)
#
# This method is here to that subclasses can redirect their output
# stream without having to do silly things like tie STDOUT (although
# they still can if they want, by overriding this method).
# ----------------------------------------------------------------------
sub __orig_print {
    my ($self, @stuff) = @_;
    my $OUT = $self->term->Attribs->{'outstream'};
    $OUT ||= *STDOUT;
    CORE::print $OUT @stuff;
}

sub print {
    my ($self, @stuff) = @_;
    CORE::print STDOUT @stuff;
}

# ----------------------------------------------------------------------
# quit([$status])
#
# Exits the interpreter with $status as the exit status (0 by default).
# ----------------------------------------------------------------------
sub quit {
    my ($self, $status) = @_;
    $status = 0 unless defined $status;

    if (my $h = $self->histfile) {
        # XXX Can this be better encapsulated?
	if ( $self->term->can("WriteHistory") ) {
	    $self->term->WriteHistory($h);
	}
	elsif ( open( my $fd, '>:encoding(utf8)', $h ) ) {
	    print { $fd } @{ $self->{_history} };
	    close($fd);
	}
    }

    return $status;
}

# ----------------------------------------------------------------------
# do_version()
#
# Show version.
# ----------------------------------------------------------------------
sub do_version {
    my $self = shift;
    return $EB::ident;
}

sub help_version {
    return _T("Toon versie.");
}

# ----------------------------------------------------------------------
# parseline($line)
#
# parseline splits a line into three components:
#
#    1. Command
#
#    3. Arguments
#
# returns an array that looks like:
#
#   ($cmd, @args)
#
# This parseline method doesn't handle pipelines gracefully; pipes
# ill treated like any other token.
# ----------------------------------------------------------------------
sub parseline {
    my ($self, $line) = @_;
    my ($cmd, @args);

    @args = shellwords($line);

    while (@args) {
	$cmd = shift @args;
	last;
    }

    return (($cmd or ""), @args);
}

# ----------------------------------------------------------------------
# term()
#
# Returns the Term::ReadLine instance.  Useful if the subclass needs
# do something like modify attributes on the instance.
# ----------------------------------------------------------------------
sub term {
    my $self = shift;
    $self->{ TERM } = shift if (@_);
    return $self->{ TERM };
}

# ----------------------------------------------------------------------
# histfile([$histfile])
#
# Gets/set the history file.
# ----------------------------------------------------------------------
sub histfile {
    my $self = shift;
    $self->{ HISTFILE } = shift if (@_);
    return $self->{ HISTFILE };
}


# ----------------------------------------------------------------------
# prompt([$prompt[, @args]])
#
# The prompt can be modified using this method.  For example, multiline
# commands (which much be handled by the subclass) might modify the
# prompt, e.g., PS1 and PS2 in bash.  If $prompt is a coderef, it is
# executed with $self and @args:
#
#   $self->{ PROMPT } = &$prompt($self, @args);
# ----------------------------------------------------------------------
sub prompt {
    my $self = shift;
    if (@_) {
        my $p = shift;
        if (ref($p) eq 'CODE') {
            $self->{ PROMPT } = &$p($self, @_);
        }
        else {
            $self->{ PROMPT } = $p;
        }
    }
    return $self->{ PROMPT };
}

# ----------------------------------------------------------------------
# help([$topic[, @args]])
#
# Displays help. With $topic, it attempts to call $self->help_$topic,
# which is expected to return a string.  Without $topic, it lists the
# available help topics, which is a list of methods that begin with
# help_; these names are massaged with s/^help_// before being displayed.
# ----------------------------------------------------------------------
sub help {
    my ($self, $topic, @args) = @_;
    my @ret;

    if ($topic) {
        if (my $sub = $self->can("help_".
				 ($self->_xtr("cmd:".lc($topic))||lc($topic)))) {
            push @ret,  $self->$sub(@_);
	    push(@ret, _T("Opdrachtnamen zijn hoofdletterongevoelig.") )
	      unless $topic eq lc($topic);
        }
        else {
            push @ret,
	      __x("Sorry, geen hulp voor {topic}.", topic => $topic);
        }
    }

    else {
        my @helps = $self->helps;
        if (@helps) {
	    push( @ret,
		  _T("Hulp is beschikbaar voor de volgende onderwerpen."),
		  _T("Typ 'help [onderwerp]' voor meer gedetailleerde informatie."),
		  _T("Opdrachtnamen zijn hoofdletterongevoelig.") );
	    my $t = "=" x max( length($ret[-1]), length($ret[-2]) );
	    push(@ret, $t, map({ "  * $_" } sort @helps), $t);
        }
        else {
            push @ret, _T("Geen hulp beschikbaar.");
        }
    }

    return join "\n", @ret;
}


# ----------------------------------------------------------------------
# helps([@helps])
#
# Returns or sets a list of possible help functions.
# ----------------------------------------------------------------------
sub helps {
    my $self = shift;

    if (@_) {
        $self->{ HELPS } = \@_;
    }

    return @{ $self->{ HELPS } };
}

# ----------------------------------------------------------------------
# complete(@_)
#
# Command completion -- this method is designed to be assigned as:
#
#   $term->Attribs->{completion_function} = sub { $self->complete(@_) };
# 
# Note the silly setup -- it will be called as a function, without
# any references to $self, so we need to force $self into the equation
# using a closure.
# ----------------------------------------------------------------------
sub complete {
    my ($self, $word, $line, $pos) = @_;
    #warn "Completing '$word' in '$line' (pos $pos)";

    # This is grossly suboptimal, and only completes on
    # defined keywords.  A better idea is to:
    #  1. If subtr($line, ' ') is less than $pos,
    #     then we are completing a command
    #     (the current method does this correctly)
    #  2. Otherwise, we are completing something else.
    #     By default, this should defer to regular filename
    #     completion.
    return grep { /$word/ } $self->completions;
}

sub completions {
    my $self = shift;

    if (@_) {
        $self->{ COMPLETIONS } = \@_;
    }

    return @{ $self->{ COMPLETIONS } };
}

1;

# =head1 AUTHOR
#
# darren chamberlain E<lt>darren@cpan.orgE<gt>
#
# Modified for EekBoek by E<lt>jv@cpan.orgE<gt>
#
# =head1 COPYRIGHT
#
# Copyright (C) 2003 darren chamberlain.  All Rights Reserved.
#
# This module is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.


# Copyrights 2001-2020 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::FastScalar;
use vars '$VERSION';
$VERSION = '3.009';


use strict;
use warnings;
use integer;


sub new($) {
    my ($class, $ref) = @_;
    $$ref = '' unless defined $$ref;
    bless { ref => $ref, pos => 0 }, $class;
}

sub autoflush() {}

sub binmode() {}

sub clearerr { return 0; }

sub flush() {}

sub sync() { return 0; }

sub opened() { return $_[0]->{ref}; }

sub open($) {
    my $self = $_[0];

    ${$_[1]} = '' unless defined(${$_[1]});
    $self->{ref} = $_[1];
    $self->{pos} = 0;
}

sub close() {
    undef $_[0]->{ref};
}

sub eof() {
    my $self = $_[0];

    return $self->{pos} >= length(${$self->{ref}});
}

sub getc() {
    my $self = $_[0];

    return substr(${$self->{ref}}, $self->{pos}++, 1);
}

sub print {
    my $self = shift;
    my $pos = $self->{pos};
    my $ref = $self->{ref};
    my $len = length($$ref);
    
    if ($pos >= $len) {
	$$ref .= $_ foreach @_;
	$self->{pos} = length($$ref);
    } else {
	my $buf = $#_ ? join('', @_) : $_[0];
	
	$len = length($buf);
	substr($$ref, $pos, $len) = $buf;
	$self->{pos} = $pos + $len;
    }
    1;
}

sub read($$;$) {
    my $self = $_[0];
    my $buf = substr(${$self->{ref}}, $self->{pos}, $_[2]);
    $self->{pos} += $_[2];

    ($_[3] ? substr($_[1], $_[3]) : $_[1]) = $buf;
    return length($buf);
}

sub sysread($$;$) {
    return shift()->read(@_);
}

sub seek($$) {
    my $self = $_[0];
    my $whence = $_[2];
    my $len = length(${$self->{ref}});

    if ($whence == 0) {
	$self->{pos} = $_[1];
    } elsif ($whence == 1) {
	$self->{pos} += $_[1];
    } elsif ($whence == 2) {
	$self->{pos} = $len + $_[1];
    } else {
	return;
    }
    if ($self->{pos} > $len) {
	$self->{pos} = $len;
    } elsif ($self->{pos} < 0) {
	$self->{pos} = 0;
    }
    return 1;
}

sub sysseek($$) {
    return $_[0]->seek($_[1], $_[2]);
}

sub setpos($) {
    return $_[0]->seek($_[1], 0);
}

sub sref() {
    return $_[0]->{ref};
}

sub getpos() {
    return $_[0]->{pos};
}

sub tell() {
    return $_[0]->{pos};
}

sub write($$;$) {
    my $self = $_[0];
    my $pos = $self->{pos};
    my $ref = $self->{ref};
    my $len = length($$ref);

    if ($pos >= $len) {
	$$ref .= substr($_[1], $_[3] || 0, $_[2]);
	$self->{pos} = length($$ref);
	$len = $self->{pos} -  $len;
    } else {
	my $buf = substr($_[1], $_[3] || 0, $_[2]);
	
	$len = length($buf);
	substr($$ref, $pos, $len) = $buf;
	$self->{pos} = $pos + $len;
    }
    return $len;
}

sub syswrite($;$$) {
    return shift()->write(@_);
}

sub getline() {
    my $self = $_[0];
    my $ref = $self->{ref};
    my $pos = $self->{pos};

    if (!defined($/) || (my $idx = index($$ref, $/, $pos)) == -1) {
	return if ($pos >= length($$ref));
	$self->{pos} = length($$ref);
	return substr($$ref, $pos);
    } else {
	return substr($$ref, $pos, ($self->{pos} = $idx + length($/)) - $pos);
    }
}

sub getlines() {
    my $self = $_[0];
    my @lines;
    my $ref = $self->{ref};
    my $pos = $self->{pos};

    if (defined($/)) {
	my $idx;
	
	while (($idx = index($$ref, $/, $pos)) != -1) {
	    push(@lines, substr($$ref, $pos, ($idx + 1) - $pos));
	    $pos = $idx + 1;
	}
    }
    my $r = substr($$ref, $pos);
    if (length($r) > 0) {
	push(@lines, $r);
    }
    $self->{pos} = length($$ref);
    return wantarray() ? @lines : \@lines;
}

sub TIEHANDLE {
    ((defined($_[1]) && UNIVERSAL::isa($_[1], "Mail::Box::FastScalar"))
         ? $_[1] : shift->new(@_));
}

sub GETC { shift()->getc(@_) }
sub PRINT { shift()->print(@_) }
sub PRINTF { shift()->print(sprintf(shift, @_)) }
sub READ { shift()->read(@_) }
sub READLINE { wantarray ? shift()->getlines(@_) : shift()->getline(@_) }
sub WRITE { shift()->write(@_); }
sub CLOSE { shift()->close(@_); }
sub SEEK { shift()->seek(@_); }
sub TELL { shift()->tell(@_); }
sub EOF { shift()->eof(@_); }

1;

1;

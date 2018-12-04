package Linux::InitFS::Entry;
use warnings;
use strict;

my %ENTRIES = ();

my $WANT_STATIC = undef;
my $ONLY_STATIC = undef;


###############################################################################
# base constructor

sub new {
	my ( $this, %args ) = @_;

	my $class = ref( $this ) || $this;

	my $obj = bless \%args, $class;

	return undef unless $obj->{path};
	return undef unless $obj->{type};

	if ( my $rv = $ENTRIES{$obj->{path}} ) {
		# FIXME sometimes this is bad...
		return $rv;
	}

	return undef unless $obj->_init_dirs();

	if ( $obj->{type} eq 'file' ) {
		return undef unless $obj->_init_prog_deps();
	}

	$ENTRIES{$obj->{path}} = $obj;

	return $obj;
}


###############################################################################
# shortcut constructors

sub new_dir {
	my ( $class, $path, %args ) = @_;

	$args{type} = 'dir';
	$args{path} = $path;

	return $class->new( %args );
}

sub new_nod {
	my ( $class, $path, $dtype, $major, $minor, %args ) = @_;

	$args{type} = 'nod';
	$args{path} = $path;
	$args{dtype} = $dtype;
	$args{major} = $major;
	$args{minor} = $minor;

	return $class->new( %args );
}

sub new_file {
	my ( $class, $path, $from, %args ) = @_;

	if ( -l $from ) {

		my $link = readlink $from
			or return;

		$class->new_slink( $path, $link );

		unless ( $link =~ /\// ) {
			my @parts = split /\//, $from;
			pop @parts;
			push @parts, $link;
			$link = join( '/', @parts );
		}

		return $class->new_host_file( $link, %args );
	}

	if ( -d $from ) {
		return $class->new_dir( $path, %args );
	}

	$args{type} = 'file';
	$args{path} = $path;
	$args{from} = $from;

	unless ( exists $args{mode} ) {
		$args{mode} = -x $from ? 0755 : 0644;
	}

	return $class->new( %args );
}

sub new_slink {
	my ( $class, $path, $from, %args ) = @_;

	$args{type} = 'slink';
	$args{path} = $path;
	$args{from} = $from;

	return $class->new( %args );
}


###############################################################################
# high-level constructors

sub new_prog {
	my ( $class, $path, $from, %args ) = @_;

	unless ( exists $args{mode} ) {
		$args{mode} = 0755;
	}

	unless ( defined $WANT_STATIC ) {
		$WANT_STATIC = Linux::InitFS::Kernel::feature_enabled( 'INITRAMFS_WITH_STATIC' );
	}

	if ( $WANT_STATIC ) {
		my $static = $from . '.static';
		$from = $static if -e $static;
	}

	return $class->new_file( $path, $from, %args );
}

sub new_host_file {
	my ( $class, $path, %args ) = @_;

	return $class->new_file( $path, $path, %args );
}

sub new_host_prog {
	my ( $class, $path, %args ) = @_;

	return $class->new_prog( $path, $path, %args );
}

sub new_mnt_point {
	my ( $class, $path, %args ) = @_;

	$args{mode} = 0000;

	return $class->new_dir( $path, %args );
}

sub new_term_type {
	my ( $class, $type ) = @_;

	my ( $char ) = ( $type =~ /^(\w)/ );

	my $file = '/etc/terminfo/' . $char . '/' . $type;

	return $class->new_host_file( $file );
}


###############################################################################
# initializers

sub _init_dirs {
	my ( $this ) = @_;

	my ( @parts ) = split /\//, $this->{path};

	while ( @parts ) {
		pop @parts;

		my $temp = join( '/', @parts );

		next unless $temp;

		$this->new_dir( $temp );

	}

	return 1;
}

sub _init_prog_deps_dynlib {
	my ( $this, $file ) = @_;

	my $found = 0;

	foreach ( `ldd $file 2>/dev/null` ) {

		next unless /=>/ || /^\s*\/lib\d*\/ld-linux/;

		chomp;
		s/^[^\/]*\//\//;
		s/\s.*$//;

		next unless $_;

		$this->new_host_file( $_, mode => /ld-linux/ ? 0755 : 0644 );

		$found++;

	}

	return $found;
}

#sub _init_prog_deps_shell {
#	my ( $this, $file ) = @_;
#
#	my $rc = open my $fh, '<', $file;
#	return unless defined $rc;
#
#	my $txt = <$fh>;
#	my ( $interpreter ) = ( $txt =~ /^#!([^\s]+)/ );
#	return unless $interpreter;
#
#	$this->new_host_prog( $interpreter );
#
#	return 1;
#}

sub _init_prog_deps {
	my ( $this ) = @_;

	my $run = $this->{from};

	unless ( defined $ONLY_STATIC ) {
		$ONLY_STATIC = Linux::InitFS::Kernel::feature_enabled( 'INITRAMFS_WITH_STATIC_ONLY' );
	}

	return 1 if $this->_init_prog_deps_dynlib( $run );
#	return 1 if $this->_init_prog_deps_shell( $run );
	return 1;
}


###############################################################################
# output-one method

sub print_entry($$) {
	my ( $this ) = @_;

	my $path = $this->{path};
	my $type = $this->{type};
	my $mode = $this->{mode};

	unless ( defined $mode ) {

		if ( $type eq 'dir' ) {
			$mode = 0755;
		}

		elsif ( $type eq 'nod' ) {
			$mode = 0600;
		}

		elsif ( $type eq 'file' ) {
			$mode = 0644;
		}

		elsif ( $type eq 'slink' ) {
			$mode = 0777;
		}

		else {
			$mode = 0000;
		}

	}

	$mode = sprintf "%o", $mode;

	my $owner = $this->{owner} || 0;
	my $group = $this->{group} || 0;

	if ( $type eq 'dir' ) {
		print join( ' ', $type, $path, $mode, $owner, $group ), "\n";
	}

	elsif ( $type eq 'nod' ) {
		my $dtype = $this->{dtype};
		my $major = $this->{major};
		my $minor = $this->{minor};

		print join( ' ', $type, $path, $mode, $owner, $group, $dtype, $major, $minor ), "\n";

	}

	elsif ( $type eq 'file' || $type eq 'slink' ) {
		my $from = $this->{from} or return;

		print join( ' ', $type, $path, $from, $mode, $owner, $group ), "\n";

	}

	else {
		warn "unknown initfs item type $type path $path\n";
	}

}


###############################################################################
# output-all method

sub execute {
	my ( $this ) = @_;

	my @order = sort { $a->{path} cmp $b->{path} } values %ENTRIES;

	my ( @dirs, @devs, @rest );

	foreach my $entry ( @order ) {

		my $path = $entry->{path};
		my $type = $entry->{type};

		if ( $type eq 'dir' ) {
			push @dirs, $entry;
		}

		elsif ( $type eq 'nod' ) {
			push @devs, $entry;
		}

		else {
			push @rest, $entry;
		}

	}

	$_->print_entry() for @dirs;
	$_->print_entry() for @devs;
	$_->print_entry() for @rest;

	return ( @dirs or @devs or @rest ) ? 1 : 0;
}


###############################################################################
# EOF
1;

package Dist::Inkt::Role::CopyFiles;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.025';

use Moose::Role;
use Types::Standard -types;
use Path::Tiny 'path';
use Path::Iterator::Rule;
use namespace::autoclean;

use constant Skippable => (CodeRef | RegexpRef | Str)->create_child_type(name => 'Skippable');

has manifest_skip => (
	is       => 'ro',
	isa      => ArrayRef[Skippable],
	lazy     => 1,
	builder  => '_build_manifest_skip',
);

has also_skip => (
	is       => 'ro',
	isa      => ArrayRef[Skippable],
	default  => sub { [] },
);

sub _build_manifest_skip
{
	my $self = shift;
	my $name = quotemeta($self->name);
	return [
		qr!^(meta|xt|blib|cover_db)/!,
		qr!^(perl-travis-helper)/!,
		qr!^\..!,
		qr!^[Dd]evel.!,
		qr!~$!,
		qr!\.(orig|patch|rej|bak|old|tmp)$!,
		qr!^$name.*\.tar.gz$!,
		@{ $self->also_skip },
	];
}

after BUILD => sub {
	my $self = shift;
	unshift @{ $self->targets }, 'Files';
};

*Path::Tiny::subsumes = sub
{
	my ($self, $other) = @_;
	return !!1 if $self eq $other;
	return !!0 if !defined $other;
	return !!0 if $other->parent eq $other;
	return $self->subsumes($other->parent);
} unless Path::Tiny->can('subsumes');

sub Build_Files
{
	my $self = shift;
	
	my $src = $self->rootdir;
	my $dest = $self->targetdir;
	my @manifest_skip = @{ $self->manifest_skip };
	
	my $rule = 'Path::Iterator::Rule'->new->and(sub {
		my $file = path($_);
		return \0 if $dest->subsumes($file);
		
		my $relative = $file->relative($src);
		for my $ms (@manifest_skip) {
			if (ref $ms eq 'CODE' and $ms->("$relative")) {
				return \0;
			}
			elsif (ref $ms eq 'Regexp' and "$relative" =~ /$ms/) {
				return \0;
			}
			elsif ($ms eq "$relative") {
				return \0;
			}
		}
		
		return 1;
	})->file;
	
	for ($rule->all($src))
	{
		my $file = path($_);
		my $relative = $file->relative($src);
		my $destfile = $relative->absolute($dest);
		$self->log("Copying $file");
		$destfile->parent->mkpath;
		$file->copy($destfile);
	}
}

1;

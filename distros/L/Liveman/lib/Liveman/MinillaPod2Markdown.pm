package Liveman::MinillaPod2Markdown;
# Обманка для Minilla, чтобы скопировать Module в README.md

use parent qw/Pod::Markdown/;

use File::Slurper qw/read_text write_text/;

sub new { bless {}, __PACKAGE__ }

sub parse_from_file {
    my ($self, $path) = @_;
    $self->{pm_path} = $path;
    $self->{md_path} = $path =~ s!\.\w+$!.md!r;
	$self->{name} = ($path =~ s!^lib/(.*)\.\w+$!$1!r) =~ s!/!-!gr;
    $self
}

sub as_markdown {
    my ($self) = @_;

    my $md = $self->read_md;
    my $pm = $self->read_pm;

    my $pm_version = $self->pm_version;
    my $v = uc "version";
    my ($md_version) = $md =~ /^#[ \t]+$v\s+([\w.-]{1,32})\s/m;
    my ($hd_version) = $pm =~ /^=head1[ \t]+VERSION\s+([\w.-]{1,32})\s/m;

    if(defined $pm_version and defined $md_version and $pm_version ne $md_version) {
        $md =~ s/(#[ \t]+$v\s+)[\w.-]{1,32}(\s)/$1$pm_version$2/;
        write_text $self->{md_path}, $md;
    }

    if(defined $pm_version and defined $hd_version and $pm_version ne $hd_version) {
        $pm =~ s/^(=head1[ \t]+VERSION\s+)[\w.-]{1,32}(\s)/$1$pm_version$2/m;
        write_text $self->{pm_path}, $pm;
    }

    $md =~ s/^!\w+:\w+(,\w+)*\s+/$self->parse_options($&)/e;

    $md
}

# parse !options on first line
sub parse_options {
	my ($self, $options) = @_;
	
	$options =~ s/^!//;
	$options =~ s/\s*$//;
	$options =~ s/^\w+:\w+,?//;
	my @options = map { $_ eq "badges"? qw/github-actions metacpan cover/: $_ } split /,/, $options;
	
	$options = join " ", map {
		if($_ eq 'github-actions') {
			my $github = $self->github_path;
			"[![Actions Status](https://github.com/$github/actions/workflows/test.yml/badge.svg)](https://github.com/$github/actions)"
		}
		elsif($_ eq 'metacpan') {
			my $name = $self->{name};
			"[![MetaCPAN Release](https://badge.fury.io/pl/$name.svg)](https://metacpan.org/release/$name)";
		}
		elsif($_ eq 'cover') {
			my $github = $self->github_path;
			my $name = $self->{name};
			my $version = $self->pm_version;
			"[![Coverage](https://raw.githubusercontent.com/$github/master/doc/badges/total.svg)](https://fast2-matrix.cpantesters.org/?dist=$name+$version)";
		}
		# elsif ($_ eq 'kwalitee') {
			# "[![Kwalitee](https://cpants.cpanauthors.org/release/DART/Liveman-3.2.svg)";
		# }
		else { () }
	} @options;
	
	$options? "$options\n": ""
}

# path project on github
sub github_path {
	my ($self) = @_;
	return $self->{github_path} if exists $self->{github_path};
	for my $r (split /\n/, `git remote -v`) {
		$self->{github_path} = $1, last if $r =~ m!git\@github\.com:(.*?)\.git!;
	}
	$self->{github_path} //= "???";
}

sub read_md {
	my ($self) = @_;
	return $self->{read_md} if exists $self->{read_md};
	$self->{read_md} = read_text($self->{md_path});
	$self->{read_md}
}

sub read_pm {
	my ($self) = @_;
	return $self->{read_pm} if exists $self->{read_pm};
	$self->{read_pm} = read_text($self->{pm_path});
	$self->{read_pm}
}

sub pm_version {
	my ($self) = @_;
	return $self->{pm_version} if exists $self->{pm_version};
	my $v = uc "version";
	($self->{pm_version}) = $self->read_pm =~ /^our\s+\$$v\s*=\s*["']?([\w.-]{1,32})/m;
	$self->{pm_version} //= '???';
}


1;

__END__

=encoding utf-8

=head1 NAME

Liveman::Minillapod2markdown - a plug for minilla, which throws Lib/Mainmodule.md to Readme.md

=head1 SYNOPSIS

	use Liveman::MinillaPod2Markdown;
	
	my $mark = Liveman::MinillaPod2Markdown->new;
	
	$mark->isa("Pod::Markdown")  # -> 1
	
	use File::Slurper qw/write_text/;
	write_text "X.md", "hi!";
	write_text "X.pm", "our \$VERSION = 1.0;";
	
	$mark->parse_from_file("X.pm");
	$mark->{pm_path}  # => X.pm
	$mark->{md_path}  # => X.md
	
	$mark->as_markdown  # => hi!

=head1 DESCRIPION

Add the C<Markdown_maker = "Liveman::MinillaPod2Markdown"> to C<minil.toml>, and Minilla will not create C<README.md> from the POD-documenting of the main module, and will take from the same name next to the extension C<*.md>.

=head1 SUBROUTINES

=head2 as_markdown ()

Plug.

=head2 new ()

Constructor.

=head2 parse_from_file ($path)

Plug.

=head2 parse_options ($options)

Parses !options on the first line:

=over

=item 1. Removes ! and languages behind him.

=item 2. He translates the badge through a comma into a Markdown picture.

=back

Badge List:

=over

=item 1. badges - all badges.

=item 2. github-actions - badge for GitHub tests.

=item 3. metacpan - badge for release.

=item 4. cover - badge for coverage that creates C<liveman> when passing the test in C<doc/badges/total.svg>.

=back

=head2 github_path ()

The project path to GitHub: username/repository.

=head2 read_md ()

Reads a file with MarkDown-documentation.

=head2 read_pm ()

Reads the module.

=head2 pm_version ()

The version of the module.

=head1 INSTALL

To install this module in your system, follow the following actions [command] (https://metacpan.org/pod/App::cpm):

	sudo cpm install -gvv Liveman::MinillaPod2Markdown

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<gplv3>

=head1 COPYRIGHT

The Liveman::MinillaPod2Markdown module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All Rights Reserved.

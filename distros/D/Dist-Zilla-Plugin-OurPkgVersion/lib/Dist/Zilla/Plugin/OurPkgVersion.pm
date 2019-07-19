package Dist::Zilla::Plugin::OurPkgVersion;
use 5.014;
use strict;
use warnings;

our $VERSION = '0.21'; # VERSION

use Moose;
with (
	'Dist::Zilla::Role::FileMunger',
	'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [
            ':InstallModules',
            ':PerlExecFiles',
        ],
	},
	'Dist::Zilla::Role::PPI',
);

use Carp qw( confess );
use PPI;
use MooseX::Types::Perl qw( LaxVersionStr );
use namespace::autoclean;

has underscore_eval_version => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);

has semantic_version => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);

has skip_main_module => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);

has overwrite => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);

has no_critic => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);

sub munge_files {
	my $self = shift;

	$self->munge_file($_) for
		grep { $self->skip_main_module ? $_->name ne $self->zilla->main_module->name : 1 }
		@{ $self->found_files };

	return;
}

sub BUILD {
	my $self = shift;

	if ($self->underscore_eval_version && $self->semantic_version) {
		confess 'You cannot setup both underscore_eval_version and semantic_version';
	}

	return 1;
}

sub munge_file {  ## no critic (Subroutines::ProhibitExcessComplexity)
	my ( $self, $file ) = @_;

	if ( $file->name =~ m/\.pod$/ixms ) {
		$self->log_debug( 'Skipping: "' . $file->name . '" is pod only');
		return;
	}

	my $version = $self->zilla->version;

	confess 'invalid characters in version'
		unless LaxVersionStr->check( $version );  ## no critic (Modules::RequireExplicitInclusion)

	my $doc = $self->ppi_document_for_file($file);

	return unless defined $doc;

	$doc->index_locations if $self->overwrite; # optimize calls to check line numbers
	my $comments = $doc->find('PPI::Token::Comment');

	my $version_regex
		= q{
                  ^
                  (\s*)              # capture leading whitespace for whole-line comments
                  (
                    \#\#?\s*VERSION  # capture # VERSION or ## VERSION
                    \b               # and ensure it ends on a word boundary
                    [                # conditionally
                      [:print:]      # all printable characters after VERSION
                      \s             # any whitespace including newlines - GH #5
                    ]*               # as many of the above as there are
                  )
                  $                  # until the EOL}
		;

	my $munged_version = 0;
	if ( ref($comments) eq 'ARRAY' ) {
		foreach ( @{ $comments } ) {
			if ( /$version_regex/xms ) {
				my ( $ws, $comment ) = ( $1, $2 );
				$comment =~ s/(?=\bVERSION\b)/TRIAL /x if $self->zilla->is_trial;
				my $code
					= "$ws"
			  		. q{our $VERSION = '}
						. $version
						. qq{'; $comment}
						;

				if ( $self->semantic_version ) {
				  confess 'Invalid semantic version syntax declaration in INI file' unless ( $version =~ /^v\d+\.\d+\.\d+$/x );
					$code = "use version;\n" . $code;
				}

				# If the comment is not a whole-line comment, and if the user wants to overwrite
				# existing "our $VERSION=...;", then find the other tokens from this line, looking
				# for our $VERSION = $VALUE.  If found, edit only the VALUE.
				if ( $self->overwrite && !$_->line ) {
					my $line_no = $_->line_number;
					my $nodes = $doc->find( sub { $_[1]->line_number == $line_no } );
					my $version_value_token = $nodes && $self->_identify_version_value_token(@$nodes);
					if ( $version_value_token ) {
						$version_value_token->set_content(qq{'$version'});
						$code = $ws . $comment;
						$munged_version++;
					}
				}

				if ( $version =~ /_/ && $self->underscore_eval_version ) {
					my $eval = "\$VERSION = eval \$VERSION;";
					$eval .= " ## no critic (BuiltinFunctions::ProhibitStringyEval)"
					  if $self->no_critic;
					$code .= $_->line? "$eval\n" : "\n$eval";
				}

				$_->set_content($code);
				$munged_version++;
			}
		}
	}

	if ( $munged_version ) {
		$self->save_ppi_document_to_file( $doc, $file);
		$self->log_debug([ 'adding $VERSION assignment to %s', $file->name ]);
	}
	else {
		$self->log( 'Skipping: "'
			. $file->name
			. '" has no "# VERSION" comment'
			);
	}
	return;
}

sub _identify_version_value_token {
	my ( $self, @tokens ) = @_;
	my $val_tok;
	my @want = ('our', '$VERSION', '=', undef, ';');
	my $i = 0;
	for ( @tokens ) {
		next if $_->isa('PPI::Token::Whitespace');
		# If the next thing we want is "undef", this is where we capture the value token.
		if (!defined $want[$i]) {
			$val_tok = $_;
			++$i;
		}
		# Else if the token matches the current step in the sequence, advance the sequence
		# If sequence completely matched, return.
		elsif ($want[$i] eq $_->content) {
			++$i;
			return $val_tok if $i >= $#want;
		}
		# A mismatch restarts the search
		elsif ($i) {
			$i = 0;
		}
	}
	return; # no match
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: No line insertion and does Package version with our

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::OurPkgVersion - No line insertion and does Package version with our

=head1 VERSION

version 0.21

=head1 SYNOPSIS

in dist.ini

	[OurPkgVersion]

in your modules

	# VERSION

=head1 DESCRIPTION

This module was created as an alternative to
L<Dist::Zilla::Plugin::PkgVersion> and uses some code from that module. This
module is designed to use a the more readable format C<our $VERSION =
$version;> as well as not change then number of lines of code in your files,
which will keep your repository more in sync with your CPAN release. It also
allows you slightly more freedom in how you specify your version.

=head2 EXAMPLES

in dist.ini

	...
	version = 0.01;
	[OurPkgVersion]

in lib/My/Module.pm

	package My::Module;
	# VERSION
	...

output lib/My/Module.pm

	package My::Module;
	our $VERSION = '0.01'; # VERSION
	...

please note that whitespace before the comment is significant so

	package My::Module;
	BEGIN {
		# VERSION
	}
	...

becomes

	package My::Module;
	BEGIN {
		our $VERSION = '0.01'; # VERSION
	}
	...

while

	package My::Module;
	BEGIN {
	# VERSION
	}
	...

becomes

	package My::Module;
	BEGIN {
	our $VERSION = '0.01'; # VERSION
	}
	...

you can also add additional comments to your comment

	...
	# VERSION: generated by DZP::OurPkgVersion
	...

becomes

	...
	our $VERSION = '0.1.0'; # VERSION: generated by DZP::OurPkgVersion
	...

you can also use perltidy's default static side comments (##)

	...
	## VERSION
	...

becomes

	...
	our $VERSION = '0.1.0'; ## VERSION
	...

Also note, the package line is not in any way significant, it will insert the
C<our $VERSION> line anywhere in the file before C<# VERSION> as many times as
you've written C<# VERSION> regardless of whether or not inserting it there is
a good idea. OurPkgVersion will not insert a version unless you have C<#
VERSION> so it is a bit more work.

If you make a trial release, the comment will be altered to say so:

	# VERSION

becomes

	our $VERSION = '0.01'; # TRIAL VERSION

=encoding UTF-8

=head1 METHODS

=over

=item BUILD

Provides validations after object creation.

=item munge_files

Override the default provided by L<Dist::Zilla::Role::FileMunger> to limit
the number of files to search to only be modules and executables.

=item munge_file

tells which files to munge, see L<Dist::Zilla::Role::FileMunger>.

=item finder

Override the default L<FileFinder|Dist::Zilla::Role::FileFinder> for
finding files to check and update. The default value is C<:InstallModules>
and C<:PerlExecFiles> (when available; otherwise C<:ExecFiles>)
-- see also L<Dist::Zilla::Plugin::ExecDir>, to make sure the script
files are properly marked as executables for the installer.

=back

=head1 PROPERTIES

=over

=item underscore_eval_version

For version numbers that have an underscore in them, add this line
immediately after the our version assignment:

	$VERSION = eval $VERSION;

This is arguably the correct thing to do, but changes the line numbering
of the generated Perl module or source, and thus optional.

=item semantic_version

Setting this property to "true" (1) will set the version of the
module/distribution to properly use semantic versioning. It will also expect
that you setup C<version> with a v-string, without adding quotes. For example:

	version = v0.0.1

Beware you can't setup both C<underscore_eval_version> and C<semantic_version>
since both are mutually exclusive: if you try, your code is going to C<die>.

For more details, check
L<this blog|https://weblog.bulknews.net/how-to-correctly-use-semantic-version-vx-y-z-in-perl-modules-eb08568ab911>
for more details about using semantic version with Perl.

=item skip_main_module

Set to true to ignore the main module in the distribution. This prevents
a warning when using L<Dist::Zilla::Plugin::VersionFromMainModule> to
obtain the version number instead of the C<dist.ini> file.

=item overwrite

When enabled, this option causes any match of the C<< # VERSION >> comment
to first check for an existing C<< our $VERSION = ...; >> on the same line,
and if found, overwrite the value in the existing statement. (the comment
still gets modified for trial releases)

Currently, the value must be a single Perl token such as a string or number.

=item no_critic

When C<underscore_eval_version> is used the generated code for dev versions
may not technically be L<Perl::Critic> compliant due to string eval, but is
nevertheless pretty safe.  This option will add the appropriate C<no critic>
directive to save you the hassle.

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/plicease/dist-zilla-plugin-ourpkgversion/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 CONTRIBUTORS

=for stopwords Alceu Rodrigues de Freitas Junior Ian Sealy Michael Conrad Jemmeson Stephan Loyd Alexandr Ciornii Alexei Znamensky Christian Walde Christopher J. Madsen David Golden Graham Ollis Graham✈️✈️

=over 4

=item *

Alceu Rodrigues de Freitas Junior <alceu.junior@quintoandar.com.br>

=item *

Ian Sealy <git@iansealy.com>

=item *

Michael Conrad <mike@nrdvana.net>

=item *

Michael Jemmeson <mjemmeson@cpan.org>

=item *

Stephan Loyd <stephanloyd9@gmail.com>

=item *

Alceu Rodrigues de Freitas Junior <arfreitas@cpan.org>

=item *

Alexandr Ciornii <alexchorny@gmail.com>

=item *

Alexei Znamensky <russoz@cpan.org>

=item *

Christian Walde <walde.christian@googlemail.com>

=item *

Christopher J. Madsen <perl@cjmweb.net>

=item *

David Golden <dagolden@cpan.org>

=item *

Graham Ollis <perl@wdlabs.com>

=item *

Graham Ollis <plicease@cpan.org>

=item *

Graham✈️✈️ <plicease@cpan.org>

=back

=head1 AUTHORS

=over 4

=item *

Caleb Cushing <xenoterracide@gmail.com>

=item *

Grahan Ollis <plicease@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Caleb Cushing.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

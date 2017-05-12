package File::RandomGenerator;
{
  $File::RandomGenerator::VERSION = '0.06';
}

# ABSTRACT: Utility to generate a random dir tree with random files.


use Modern::Perl;
use Moose;
use namespace::autoclean;
use File::Path;
use File::Temp;
use Carp;
use Smart::Args;
use Data::Dumper;
use Cwd;

use constant DEPTH => 1;
use constant WIDTH => 1;
use constant FILE_CNT => 10;
use constant ROOT_DIR => '/tmp';
use constant UNLINK => 0;



has 'depth' => ( is      => 'rw',
				 isa     => 'Int',
				 default => DEPTH
);


has 'num_files' => ( is      => 'rw',
					 isa     => 'Int',
					 default => FILE_CNT
);



has 'root_dir' => ( is      => 'rw',
					isa     => 'Str',
					default => ROOT_DIR,
);

has '_template' => ( is      => 'rw',
					isa     => 'Str',
					default => 'frgXXXXXX'
);


has 'unlink' => ( is      => 'rw',
				  isa     => 'Bool',
				  default => UNLINK
);


has 'width' => ( is      => 'rw',
				 isa     => 'Int',
				 default => WIDTH
);


#
# private attributes
#
has '_file_temp_list' => ( is      => 'rw',
						   isa     => 'ArrayRef[ File::Temp ]',
						   default => sub { [] }
);


sub BUILD {
	my $self = shift;

	if ( !-d $self->root_dir ) {
		mkpath $self->root_dir;
	}
}


sub generate {
	my $self = shift;

	my $orig_dir = getcwd();
	my $file_tmp = File::Temp->new( UNLINK => $self->unlink );

	my $list = $self->_file_temp_list;
	push @$list, $file_tmp;
	$self->_file_temp_list($list);

	my $cnt = $self->_gen_level( file_tmp   => $file_tmp,
					   curr_depth => 1,
					   want_num   => $self->num_files,
					   want_width => $self->width,
					   curr_dir   => $self->root_dir,
	);

	chdir $orig_dir or confess "failed to chdir back to $orig_dir: $!";
	
	return $cnt;
}

sub _gen_level {
	
	args my $self      => __PACKAGE__,
		my $file_tmp   => 'File::Temp',
		my $curr_depth => 'Int',
		my $want_num   => 'Int',
		my $want_width => 'Int',
		my $curr_dir   => 'Str';

	my $cnt = 0;
	
	for ( my $i = 0; $i < $want_num; $i++ ) {

		my ( $fh, $filename )
			= $file_tmp->tempfile( $self->_template,
								   DIR    => $curr_dir,
								   UNLINK => 0
			);
		close $fh;
		$cnt++;
	}

	if ( $curr_depth < $self->depth ) {

		for ( my $w = 0; $w < $want_width; $w++ ) {

			my $dir = $file_tmp->newdir( DIR => $curr_dir, CLEANUP => 0 );
			chdir $dir or confess "failed to chdir $dir: $!";
			
			$cnt+= $self->_gen_level( file_tmp   => $file_tmp,
							   curr_depth => $curr_depth + 1,
							   want_num   => $want_num * 2,
							   want_width => $want_width * 2,
							   curr_dir   => $dir->{DIRNAME},
			);

			chdir '..' or confess "failed to chdir: $!";
		}
	}
	
	return $cnt;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::RandomGenerator - Utility to generate a random dir tree with random files.

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  my $frg = File::RandomGenerator->new;
  $frg->generate;

  my $frg = File::RandomGenerator->new( 
	  depth     => 2,
	  width     => 3,
	  num_files => 2,
	  root_dir  => '/tmp',
	  unlink    => 1,
  );
  $frg->generate;

=head1 ATTRIBUTES

=head2 depth

Max directory depth.  Default is 1.

=head2 num_files

Number of files to create in the root_dir.  This number is doubled at each depth level.  For example:

  /tmp             (10 files)
  /tmp/dir_a       (20 files)
  /tmp/dir_a/dir_b (40 files)

Default is 10.

=head2 root_dir

Directory to put temp files and dirs.  Default is /tmp.

=head2 unlink

Flag to indicate whether or not to unlink the files and directories after the object goes out of scope.  Default is 1.

=head2 width

Number of subdirs to create at each depth level.

=head1 METHODS

=head2 new( %attrs )

Constructor, 'nuff said.

=head2 generate()

Generate files and directories.  Returns the number of files created.

=head1 AUTHOR

John Gravatt <john@gravatt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by John Gravatt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

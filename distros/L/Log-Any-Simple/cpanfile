# DO NOT EDIT! This file is written by perl_setup_dist.
# If needed, you can add content at the end of the file.

requires 'perl', '5.22.0';

on 'configure' => sub {
  requires 'perl', '5.22.0';
  requires 'ExtUtils::MakeMaker::CPANfile', '0.0.9';
};

on 'test' => sub {
  requires 'Test::CPANfile';
  requires 'Test::More';
  requires 'Test2::V0';
  requires 'Readonly';
  recommends 'Test::Pod', '1.22';
  recommends 'CPAN::Common::Index::Mux::Ordered';
  suggests 'IPC::Run3';  # Only used for spell-checking which is not included in the distribution
  suggests 'Test2::Tools::PerlCritic';
  suggests 'Perl::Tidy', '20220613';
};

# Develop phase dependencies are usually not installed, this is what we want as
# Devel::Cover has many dependencies.
on 'develop' => sub {
  recommends 'Devel::Cover';
  suggests 'CPAN::Uploader';
  suggests 'PAR::Packer';
  suggests 'Dist::Setup';
};

# End of the template. You can add custom content below this line.

requires 'Log::Any', '1.711';
requires 'Readonly'

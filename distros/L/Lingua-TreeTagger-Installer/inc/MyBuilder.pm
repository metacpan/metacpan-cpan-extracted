package MyBuilder;
use base 'Module::Build';
use File::Copy;

sub ACTION_install {
    $_[0]->SUPER::ACTION_install;
    warn "TreeTagger binaries should be installed.\n";
    warn "Use tree-tagger-install-lang to install parameter files.\n";
}

sub process_treelib_files {
    my $builder = shift;

    return unless -d "treetagger/lib";

    my @files = grep { -f $_ }  @{$builder->rscan_dir("treetagger/lib")};
    for my $file (@files) {
        $builder->copy_if_modified( from => $file, to_dir =>  "blib/treelib", flatten => 1 );
    }
}

sub process_sitebin_files {
    my $builder = shift;

    my @files = grep { -f $_ } @{$builder->rscan_dir("treetagger/bin")};
    for my $file (@files) {
        chmod 0755, $file;
        $builder->copy_if_modified(from=>$file, to_dir=>"blib/sitebin", flatten => 1 );
    }
}

sub process_treebin_files {
    my  $builder = shift;

    my @files = grep { -f $_ }  @{$builder->rscan_dir("treetagger/cmd")};
    for my $file (@files) {
        chmod 0755, $file;
        $builder->copy_if_modified(from=>$file, to_dir=>"blib/treebin", flatten => 1 );
    }
}

"troue";

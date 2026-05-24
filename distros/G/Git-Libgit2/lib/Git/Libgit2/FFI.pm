# ABSTRACT: Internal FFI::Platypus instance for Git::Libgit2

package Git::Libgit2::FFI;
use strict;
use warnings;
use FFI::Platypus 2.00;
use Alien::Libgit2;

my $ffi;

sub ffi {
  return $ffi if $ffi;
  $ffi = FFI::Platypus->new( api => 2, lib => [ Alien::Libgit2->dynamic_libs ] );

  $ffi->type( 'opaque' => 'git_repository'   );
  $ffi->type( 'opaque' => 'git_reference'    );
  $ffi->type( 'opaque' => 'git_reference_iterator' );
  $ffi->type( 'opaque' => 'git_config'       );
  $ffi->type( 'opaque' => 'git_object'       );
  $ffi->type( 'opaque' => 'git_blob'         );
  $ffi->type( 'opaque' => 'git_tree'         );
  $ffi->type( 'opaque' => 'git_treebuilder'  );
  $ffi->type( 'opaque' => 'git_commit'       );
  $ffi->type( 'opaque' => 'git_remote'       );
  $ffi->type( 'opaque' => 'git_signature'    );
  $ffi->type( 'opaque' => 'git_odb'          );
  $ffi->type( 'opaque' => 'git_credential'   );
  $ffi->type( 'opaque' => 'git_revwalk'      );
  $ffi->type( 'opaque' => 'git_branch_iterator' );
  $ffi->type( 'opaque' => 'git_tag'          );
  $ffi->type( 'opaque' => 'git_diff'         );
  $ffi->type( 'opaque' => 'git_index'        );

  # git_credential_acquire_cb signature.
  # libgit2: int (*)(git_credential **out, const char *url,
  #                  const char *username_from_url,
  #                  unsigned int allowed_types, void *payload)
  # Closures in FFI::Platypus allow only native types — so the **out** is passed
  # as a plain `opaque` (the pointer value). The Perl closure pokes the
  # allocated credential pointer into that address itself.
  $ffi->type( '(opaque, string, string, uint, opaque)->int' => 'git_credential_acquire_cb' );

  # git_oid is a 20-byte struct, but for our MVP we pass it as opaque
  # buffer (string of 20 bytes) or as hex via _fromstr/_tostr.
  $ffi->type( 'opaque' => 'git_oid_ptr' );

  _attach_all();
  return $ffi;
}

sub _attach {
  my ( $name, $args, $ret ) = @_;
  $ffi->attach( $name => $args => $ret );
}

sub _attach_all {
  # Library init / shutdown
  _attach git_libgit2_init     => []                          => 'int';
  _attach git_libgit2_shutdown => []                          => 'int';
  _attach git_libgit2_version  => [ 'int*', 'int*', 'int*' ]  => 'int';

  # Error
  _attach git_error_last       => []                          => 'opaque';
  _attach git_error_clear      => []                          => 'void';

  # Repository
  _attach git_repository_open      => [ 'opaque*', 'string' ]                       => 'int';
  _attach git_repository_open_ext  => [ 'opaque*', 'string', 'uint32', 'string' ]   => 'int';
  _attach git_repository_init      => [ 'opaque*', 'string', 'uint32' ]             => 'int';
  _attach git_repository_workdir   => [ 'git_repository' ]                          => 'string';
  _attach git_repository_path      => [ 'git_repository' ]                          => 'string';
  _attach git_repository_is_bare   => [ 'git_repository' ]                          => 'int';
  _attach git_repository_free      => [ 'git_repository' ]                          => 'void';

  # Config
  _attach git_config_open_default          => [ 'opaque*' ]                                 => 'int';
  _attach git_repository_config            => [ 'opaque*', 'git_repository' ]               => 'int';
  _attach git_repository_config_snapshot   => [ 'opaque*', 'git_repository' ]               => 'int';
  _attach git_config_snapshot              => [ 'opaque*', 'git_config' ]                   => 'int';
  _attach git_config_get_string            => [ 'string*', 'git_config', 'string' ]         => 'int';
  _attach git_config_set_string            => [ 'git_config', 'string', 'string' ]          => 'int';
  _attach git_config_free                  => [ 'git_config' ]                              => 'void';

  # OID
  _attach git_oid_fromstr          => [ 'opaque', 'string' ]                        => 'int';
  _attach git_oid_tostr            => [ 'opaque', 'size_t', 'opaque' ]              => 'string';
  _attach git_oid_cmp              => [ 'opaque', 'opaque' ]                        => 'int';

  # Reference
  _attach git_reference_lookup     => [ 'opaque*', 'git_repository', 'string' ]                                  => 'int';
  _attach git_reference_name_to_id => [ 'opaque',  'git_repository', 'string' ]                                  => 'int';
  _attach git_reference_create     => [ 'opaque*', 'git_repository', 'string', 'opaque', 'int', 'string' ]       => 'int';
  _attach git_reference_delete     => [ 'git_reference' ]                                                        => 'int';
  _attach git_reference_remove     => [ 'git_repository', 'string' ]                                             => 'int';
  _attach git_reference_target     => [ 'git_reference' ]                                                        => 'opaque';
  _attach git_reference_name       => [ 'git_reference' ]                                                        => 'string';
  _attach git_reference_type       => [ 'git_reference' ]                                                        => 'int';
  _attach git_reference_free       => [ 'git_reference' ]                                                        => 'void';
  _attach git_reference_iterator_new       => [ 'opaque*', 'git_repository' ]                                    => 'int';
  _attach git_reference_iterator_glob_new  => [ 'opaque*', 'git_repository', 'string' ]                          => 'int';
  _attach git_reference_next               => [ 'opaque*', 'git_reference_iterator' ]                            => 'int';
  _attach git_reference_next_name          => [ 'string*', 'git_reference_iterator' ]                            => 'int';
  _attach git_reference_iterator_free      => [ 'git_reference_iterator' ]                                       => 'void';
  _attach git_reference_name_is_valid      => [ 'int*', 'string' ]                                               => 'int';

  # Object
  _attach git_object_lookup        => [ 'opaque*', 'git_repository', 'opaque', 'int' ]                           => 'int';
  _attach git_object_id            => [ 'git_object' ]                                                           => 'opaque';
  _attach git_object_type          => [ 'git_object' ]                                                           => 'int';
  _attach git_object_free          => [ 'git_object' ]                                                           => 'void';

  # Blob
  _attach git_blob_create_from_buffer => [ 'opaque', 'git_repository', 'opaque', 'size_t' ]                      => 'int';
  _attach git_blob_lookup             => [ 'opaque*', 'git_repository', 'opaque' ]                               => 'int';
  _attach git_blob_rawcontent         => [ 'git_blob' ]                                                          => 'opaque';
  _attach git_blob_rawsize            => [ 'git_blob' ]                                                          => 'sint64';
  _attach git_blob_free               => [ 'git_blob' ]                                                          => 'void';

  # Tree
  _attach git_tree_lookup          => [ 'opaque*', 'git_repository', 'opaque' ]                                  => 'int';
  _attach git_tree_entrycount      => [ 'git_tree' ]                                                             => 'size_t';
  _attach git_tree_entry_byindex   => [ 'git_tree', 'size_t' ]                                                   => 'opaque';
  _attach git_tree_entry_byname    => [ 'git_tree', 'string' ]                                                   => 'opaque';
  _attach git_tree_entry_name      => [ 'opaque' ]                                                               => 'string';
  _attach git_tree_entry_id        => [ 'opaque' ]                                                               => 'opaque';
  _attach git_tree_entry_filemode  => [ 'opaque' ]                                                               => 'int';
  _attach git_tree_entry_type      => [ 'opaque' ]                                                               => 'int';
  _attach git_tree_free            => [ 'git_tree' ]                                                             => 'void';

  # TreeBuilder
  _attach git_treebuilder_new      => [ 'opaque*', 'git_repository', 'opaque' ]                                  => 'int';
  _attach git_treebuilder_insert   => [ 'opaque*', 'git_treebuilder', 'string', 'opaque', 'int' ]                => 'int';
  _attach git_treebuilder_remove   => [ 'git_treebuilder', 'string' ]                                            => 'int';
  _attach git_treebuilder_write    => [ 'opaque', 'git_treebuilder' ]                                            => 'int';
  _attach git_treebuilder_free     => [ 'git_treebuilder' ]                                                      => 'void';

  # Commit
  _attach git_commit_lookup        => [ 'opaque*', 'git_repository', 'opaque' ]                                  => 'int';
  _attach git_commit_create        => [ 'opaque', 'git_repository', 'string', 'git_signature', 'git_signature',
                                        'string', 'string', 'git_tree', 'size_t', 'opaque' ]                     => 'int';
  _attach git_commit_message       => [ 'git_commit' ]                                                           => 'string';
  _attach git_commit_tree          => [ 'opaque*', 'git_commit' ]                                                => 'int';
  _attach git_commit_tree_id       => [ 'git_commit' ]                                                           => 'opaque';
  _attach git_commit_parentcount   => [ 'git_commit' ]                                                           => 'uint';
  _attach git_commit_parent_id     => [ 'git_commit', 'uint' ]                                                   => 'opaque';
  _attach git_commit_author        => [ 'git_commit' ]                                                           => 'opaque';
  _attach git_commit_committer     => [ 'git_commit' ]                                                           => 'opaque';
  _attach git_commit_free          => [ 'git_commit' ]                                                           => 'void';

  # Signature
  _attach git_signature_new        => [ 'opaque*', 'string', 'string', 'sint64', 'int' ]                         => 'int';
  _attach git_signature_now        => [ 'opaque*', 'string', 'string' ]                                          => 'int';
  _attach git_signature_default    => [ 'opaque*', 'git_repository' ]                                            => 'int';
  _attach git_signature_free       => [ 'git_signature' ]                                                        => 'void';

  # Remote
  _attach git_remote_lookup            => [ 'opaque*', 'git_repository', 'string' ]                                  => 'int';
  _attach git_remote_create            => [ 'opaque*', 'git_repository', 'string', 'string' ]                        => 'int';
  _attach git_remote_create_anonymous  => [ 'opaque*', 'git_repository', 'string' ]                                  => 'int';
  _attach git_remote_url               => [ 'git_remote' ]                                                           => 'string';
  _attach git_remote_name              => [ 'git_remote' ]                                                           => 'string';
  _attach git_remote_init_callbacks    => [ 'opaque', 'uint' ]                                                       => 'int';
  _attach git_fetch_options_init       => [ 'opaque', 'uint' ]                                                       => 'int';
  _attach git_push_options_init        => [ 'opaque', 'uint' ]                                                       => 'int';
  # opts/refspecs passed as 'opaque' — we allocate the struct buffers in Perl.
  _attach git_remote_fetch             => [ 'git_remote', 'opaque', 'opaque', 'string' ]                             => 'int';
  _attach git_remote_push              => [ 'git_remote', 'opaque', 'opaque' ]                                       => 'int';
  # connect/ls/disconnect — used by Git::Native::Remote for --prune support.
  _attach git_remote_connect           => [ 'git_remote', 'int', 'opaque', 'opaque', 'opaque' ]                      => 'int';
  _attach git_remote_ls                => [ 'opaque*', 'size_t*', 'git_remote' ]                                     => 'int';
  _attach git_remote_disconnect        => [ 'git_remote' ]                                                           => 'int';
  _attach git_remote_free              => [ 'git_remote' ]                                                           => 'void';

  # Credentials — these allocate a git_credential* the callback hands back to libgit2.
  _attach git_credential_userpass_plaintext_new => [ 'opaque*', 'string', 'string' ]                          => 'int';
  _attach git_credential_ssh_key_new            => [ 'opaque*', 'string', 'string', 'string', 'string' ]      => 'int';
  _attach git_credential_ssh_key_from_agent     => [ 'opaque*', 'string' ]                                    => 'int';
  _attach git_credential_default_new            => [ 'opaque*' ]                                              => 'int';
  _attach git_credential_username_new           => [ 'opaque*', 'string' ]                                    => 'int';
  _attach git_credential_free                   => [ 'git_credential' ]                                       => 'void';

  # Clone — top-level convenience that does init + remote + fetch + checkout.
  # Options struct is allocated in Perl as opaque buffer; size probed and padded.
  _attach git_clone_options_init       => [ 'opaque', 'uint' ]                                                     => 'int';
  _attach git_clone                    => [ 'opaque*', 'string', 'string', 'opaque' ]                              => 'int';

  # Strarray cleanup (used for tag list, branch list iteration, etc.)
  _attach git_strarray_free            => [ 'opaque' ]                                                             => 'void';

  # Revwalk — iterate commits in topological / time order.
  _attach git_revwalk_new              => [ 'opaque*', 'git_repository' ]                                          => 'int';
  _attach git_revwalk_push             => [ 'git_revwalk', 'opaque' ]                                              => 'int';
  _attach git_revwalk_push_head        => [ 'git_revwalk' ]                                                        => 'int';
  _attach git_revwalk_push_ref         => [ 'git_revwalk', 'string' ]                                              => 'int';
  _attach git_revwalk_push_glob        => [ 'git_revwalk', 'string' ]                                              => 'int';
  _attach git_revwalk_push_range       => [ 'git_revwalk', 'string' ]                                              => 'int';
  _attach git_revwalk_hide             => [ 'git_revwalk', 'opaque' ]                                              => 'int';
  _attach git_revwalk_hide_head        => [ 'git_revwalk' ]                                                        => 'int';
  _attach git_revwalk_hide_ref         => [ 'git_revwalk', 'string' ]                                              => 'int';
  _attach git_revwalk_hide_glob        => [ 'git_revwalk', 'string' ]                                              => 'int';
  _attach git_revwalk_next             => [ 'opaque', 'git_revwalk' ]                                              => 'int';
  _attach git_revwalk_sorting          => [ 'git_revwalk', 'uint' ]                                                => 'int';
  _attach git_revwalk_reset            => [ 'git_revwalk' ]                                                        => 'int';
  _attach git_revwalk_simplify_first_parent => [ 'git_revwalk' ]                                                   => 'int';
  _attach git_revwalk_free             => [ 'git_revwalk' ]                                                        => 'void';

  # Branch — wraps git_reference under the hood but with branch-specific helpers.
  _attach git_branch_create            => [ 'opaque*', 'git_repository', 'string', 'git_commit', 'int' ]           => 'int';
  _attach git_branch_lookup            => [ 'opaque*', 'git_repository', 'string', 'int' ]                         => 'int';
  _attach git_branch_delete            => [ 'git_reference' ]                                                      => 'int';
  _attach git_branch_iterator_new      => [ 'opaque*', 'git_repository', 'int' ]                                   => 'int';
  _attach git_branch_next              => [ 'opaque*', 'int*', 'git_branch_iterator' ]                             => 'int';
  _attach git_branch_iterator_free     => [ 'git_branch_iterator' ]                                                => 'void';
  _attach git_branch_name              => [ 'string*', 'git_reference' ]                                           => 'int';
  _attach git_branch_is_head           => [ 'git_reference' ]                                                      => 'int';
  _attach git_branch_move              => [ 'opaque*', 'git_reference', 'string', 'int' ]                          => 'int';

  # Status — uses foreach callback to avoid walking git_status_entry structs.
  # Callback: int (*)(const char *path, unsigned int status_flags, void *payload)
  $ffi->type( '(string, uint, opaque)->int' => 'git_status_cb' );
  _attach git_status_options_init      => [ 'opaque', 'uint' ]                                                     => 'int';
  _attach git_status_foreach           => [ 'git_repository', 'git_status_cb', 'opaque' ]                          => 'int';
  _attach git_status_foreach_ext       => [ 'git_repository', 'opaque', 'git_status_cb', 'opaque' ]                => 'int';
  _attach git_status_file              => [ 'uint*', 'git_repository', 'string' ]                                  => 'int';

  # Tag — annotated and lightweight.
  _attach git_tag_create               => [ 'opaque', 'git_repository', 'string', 'git_object', 'git_signature', 'string', 'int' ] => 'int';
  _attach git_tag_create_lightweight   => [ 'opaque', 'git_repository', 'string', 'git_object', 'int' ]            => 'int';
  _attach git_tag_lookup               => [ 'opaque*', 'git_repository', 'opaque' ]                                => 'int';
  _attach git_tag_delete               => [ 'git_repository', 'string' ]                                           => 'int';
  _attach git_tag_list                 => [ 'opaque', 'git_repository' ]                                           => 'int';
  _attach git_tag_list_match           => [ 'opaque', 'string', 'git_repository' ]                                 => 'int';
  _attach git_tag_target               => [ 'opaque*', 'git_tag' ]                                                 => 'int';
  _attach git_tag_target_id            => [ 'git_tag' ]                                                            => 'opaque';
  _attach git_tag_message              => [ 'git_tag' ]                                                            => 'string';
  _attach git_tag_name                 => [ 'git_tag' ]                                                            => 'string';
  _attach git_tag_tagger               => [ 'git_tag' ]                                                            => 'opaque';
  _attach git_tag_free                 => [ 'git_tag' ]                                                            => 'void';

  # Diff — tree-to-tree / tree-to-workdir / index-to-workdir.
  _attach git_diff_options_init        => [ 'opaque', 'uint' ]                                                     => 'int';
  _attach git_diff_tree_to_tree        => [ 'opaque*', 'git_repository', 'git_tree', 'git_tree', 'opaque' ]        => 'int';
  _attach git_diff_tree_to_workdir     => [ 'opaque*', 'git_repository', 'git_tree', 'opaque' ]                    => 'int';
  _attach git_diff_tree_to_index       => [ 'opaque*', 'git_repository', 'git_tree', 'git_index', 'opaque' ]       => 'int';
  _attach git_diff_index_to_workdir    => [ 'opaque*', 'git_repository', 'git_index', 'opaque' ]                   => 'int';
  _attach git_diff_num_deltas          => [ 'git_diff' ]                                                           => 'size_t';
  _attach git_diff_get_delta           => [ 'git_diff', 'size_t' ]                                                 => 'opaque';
  _attach git_diff_free                => [ 'git_diff' ]                                                           => 'void';

  # Index — needed for diff_index_to_workdir.
  _attach git_repository_index         => [ 'opaque*', 'git_repository' ]                                          => 'int';
  _attach git_index_free               => [ 'git_index' ]                                                          => 'void';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Libgit2::FFI - Internal FFI::Platypus instance for Git::Libgit2

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Git::Libgit2::FFI;
  my $ffi = Git::Libgit2::FFI::ffi();

=head1 DESCRIPTION

Internal use only. Holds the singleton C<FFI::Platypus> instance with all
attached libgit2 functions. Consumers should use L<Git::Libgit2> instead.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-git-libgit2/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

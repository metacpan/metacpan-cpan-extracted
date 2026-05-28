# ABSTRACT: Internal FFI::Platypus instance for Git::Libgit2

package Git::Libgit2::FFI;
our $VERSION = '0.002';
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
  $ffi->type( 'opaque' => 'git_index_entry' );
  $ffi->type( 'opaque' => 'git_annotated_commit' );
  $ffi->type( 'opaque' => 'git_merge_head' );
  $ffi->type( 'opaque' => 'git_reflog' );
  $ffi->type( 'opaque' => 'git_reflog_entry' );
  $ffi->type( 'opaque' => 'git_rebase' );
  $ffi->type( 'opaque' => 'git_rebase_operation' );

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

  # ========================
  # Library init / shutdown
  # ========================

  _attach git_libgit2_init     => []                          => 'int';
  _attach git_libgit2_shutdown => []                          => 'int';
  _attach git_libgit2_version  => [ 'int*', 'int*', 'int*' ]  => 'int';

  # ========================
  # Error
  # ========================

  _attach git_error_last       => []                          => 'opaque';
  _attach git_error_clear      => []                          => 'void';

  # ========================
  # Repository
  # ========================

  _attach git_repository_open      => [ 'opaque*', 'string' ]                       => 'int';
  _attach git_repository_open_ext  => [ 'opaque*', 'string', 'uint32', 'string' ]   => 'int';
  _attach git_repository_init      => [ 'opaque*', 'string', 'uint32' ]             => 'int';
  _attach git_repository_workdir   => [ 'git_repository' ]                          => 'string';
  _attach git_repository_path      => [ 'git_repository' ]                          => 'string';
  _attach git_repository_is_bare   => [ 'git_repository' ]                          => 'int';
  _attach git_repository_free      => [ 'git_repository' ]                          => 'void';
  _attach git_repository_index     => [ 'opaque*', 'git_repository' ]              => 'int';
  _attach git_repository_config    => [ 'opaque*', 'git_repository' ]               => 'int';
  _attach git_repository_config_snapshot => [ 'opaque*', 'git_repository' ]         => 'int';
  _attach git_repository_odb       => [ 'opaque*', 'git_repository' ]              => 'int';
  _attach git_repository_set_head  => [ 'git_repository', 'string' ]               => 'int';
  _attach git_repository_head      => [ 'opaque*', 'git_repository' ]              => 'int';
  _attach git_repository_head_unborn   => [ 'git_repository' ]                     => 'int';
  _attach git_repository_head_detached => [ 'git_repository' ]                     => 'int';

  # ========================
  # Config
  # ========================

  _attach git_config_open_default => [ 'opaque*' ]                                 => 'int';
  _attach git_config_snapshot     => [ 'opaque*', 'git_config' ]                   => 'int';
  _attach git_config_get_string   => [ 'string*', 'git_config', 'string' ]         => 'int';
  _attach git_config_set_string   => [ 'git_config', 'string', 'string' ]          => 'int';
  _attach git_config_free         => [ 'git_config' ]                              => 'void';

  # ========================
  # OID
  # ========================

  _attach git_oid_fromstr    => [ 'opaque', 'string' ]                        => 'int';
  _attach git_oid_tostr      => [ 'opaque', 'size_t', 'opaque' ]              => 'string';
  _attach git_oid_cmp        => [ 'opaque', 'opaque' ]                        => 'int';

  # ========================
  # Reference
  # ========================

  _attach git_reference_lookup      => [ 'opaque*', 'git_repository', 'string' ]                                  => 'int';
  _attach git_reference_name_to_id   => [ 'opaque', 'git_repository', 'string' ]                                => 'int';
  _attach git_reference_create      => [ 'opaque*', 'git_repository', 'string', 'opaque', 'int', 'string' ]       => 'int';
  _attach git_reference_delete      => [ 'git_reference' ]                                                        => 'int';
  _attach git_reference_remove      => [ 'git_repository', 'string' ]                                             => 'int';
  _attach git_reference_target      => [ 'git_reference' ]                                                        => 'opaque';
  _attach git_reference_name        => [ 'git_reference' ]                                                        => 'string';
  _attach git_reference_type        => [ 'git_reference' ]                                                        => 'int';
  _attach git_reference_free        => [ 'git_reference' ]                                                        => 'void';
  _attach git_reference_iterator_new      => [ 'opaque*', 'git_repository' ]                                    => 'int';
  _attach git_reference_iterator_glob_new => [ 'opaque*', 'git_repository', 'string' ]                          => 'int';
  _attach git_reference_next               => [ 'opaque*', 'git_reference_iterator' ]                            => 'int';
  _attach git_reference_next_name         => [ 'string*', 'git_reference_iterator' ]                            => 'int';
  _attach git_reference_iterator_free     => [ 'git_reference_iterator' ]                                       => 'void';
  _attach git_reference_name_is_valid     => [ 'int*', 'string' ]                                               => 'int';
  _attach git_reference_peel             => [ 'opaque*', 'git_reference', 'int' ]                                => 'int';
  _attach git_reference_symbolic_create  => [ 'opaque*', 'git_repository', 'string', 'string', 'int', 'string' ] => 'int';
  _attach git_reference_symbolic_target  => [ 'git_reference' ]                                                  => 'string';
  _attach git_reference_symbolic_set_target => [ 'opaque*', 'git_reference', 'string', 'string' ]                => 'int';
  _attach git_reference_set_target       => [ 'opaque*', 'git_reference', 'opaque', 'string' ]                   => 'int';
  _attach git_reference_resolve          => [ 'opaque*', 'git_reference' ]                                       => 'int';
  _attach git_reference_shorthand        => [ 'git_reference' ]                                                  => 'string';
  _attach git_reference_is_branch        => [ 'git_reference' ]                                                  => 'int';
  _attach git_reference_is_remote        => [ 'git_reference' ]                                                  => 'int';
  _attach git_reference_is_tag           => [ 'git_reference' ]                                                  => 'int';

  # ========================
  # Object
  # ========================

  _attach git_object_lookup   => [ 'opaque*', 'git_repository', 'opaque', 'int' ]                           => 'int';
  _attach git_object_id       => [ 'git_object' ]                                                           => 'opaque';
  _attach git_object_type     => [ 'git_object' ]                                                           => 'int';
  _attach git_object_free     => [ 'git_object' ]                                                           => 'void';

  # ========================
  # Blob
  # ========================

  _attach git_blob_create_from_buffer => [ 'opaque', 'git_repository', 'opaque', 'size_t' ]                      => 'int';
  _attach git_blob_lookup            => [ 'opaque*', 'git_repository', 'opaque' ]                               => 'int';
  _attach git_blob_rawcontent        => [ 'git_blob' ]                                                          => 'opaque';
  _attach git_blob_rawsize           => [ 'git_blob' ]                                                          => 'sint64';
  _attach git_blob_is_binary         => [ 'git_blob' ]                                                          => 'int';
  _attach git_blob_free             => [ 'git_blob' ]                                                          => 'void';

  # ========================
  # Tree
  # ========================

  _attach git_tree_lookup      => [ 'opaque*', 'git_repository', 'opaque' ]                                  => 'int';
  _attach git_tree_entrycount  => [ 'git_tree' ]                                                             => 'size_t';
  _attach git_tree_entry_byindex => [ 'git_tree', 'size_t' ]                                                   => 'opaque';
  _attach git_tree_entry_byname  => [ 'git_tree', 'string' ]                                                   => 'opaque';
  _attach git_tree_entry_name   => [ 'opaque' ]                                                               => 'string';
  _attach git_tree_entry_id     => [ 'opaque' ]                                                               => 'opaque';
  _attach git_tree_entry_filemode => [ 'opaque' ]                                                               => 'int';
  _attach git_tree_entry_type   => [ 'opaque' ]                                                               => 'int';
  _attach git_tree_free         => [ 'git_tree' ]                                                             => 'void';

  # ========================
  # TreeBuilder
  # ========================

  _attach git_treebuilder_new     => [ 'opaque*', 'git_repository', 'opaque' ]                                  => 'int';
  _attach git_treebuilder_insert  => [ 'opaque*', 'git_treebuilder', 'string', 'opaque', 'int' ]                => 'int';
  _attach git_treebuilder_remove  => [ 'git_treebuilder', 'string' ]                                            => 'int';
  _attach git_treebuilder_write   => [ 'opaque', 'git_treebuilder' ]                                            => 'int';
  _attach git_treebuilder_free    => [ 'git_treebuilder' ]                                                      => 'void';

  # ========================
  # Commit
  # ========================

  _attach git_commit_lookup     => [ 'opaque*', 'git_repository', 'opaque' ]                                  => 'int';
  _attach git_commit_create     => [ 'opaque', 'git_repository', 'string', 'git_signature', 'git_signature',
                                     'string', 'string', 'git_tree', 'size_t', 'opaque' ]                     => 'int';
  _attach git_commit_message    => [ 'git_commit' ]                                                           => 'string';
  _attach git_commit_tree       => [ 'opaque*', 'git_commit' ]                                                => 'int';
  _attach git_commit_tree_id    => [ 'git_commit' ]                                                           => 'opaque';
  _attach git_commit_parentcount => [ 'git_commit' ]                                                           => 'uint';
  _attach git_commit_parent_id   => [ 'git_commit', 'uint' ]                                                   => 'opaque';
  _attach git_commit_author     => [ 'git_commit' ]                                                           => 'opaque';
  _attach git_commit_committer  => [ 'git_commit' ]                                                           => 'opaque';
  _attach git_commit_id          => [ 'git_commit' ]                                                          => 'opaque';
  _attach git_commit_time        => [ 'git_commit' ]                                                          => 'sint64';
  _attach git_commit_time_offset => [ 'git_commit' ]                                                          => 'int';
  _attach git_commit_summary     => [ 'git_commit' ]                                                          => 'string';
  _attach git_commit_free       => [ 'git_commit' ]                                                           => 'void';

  # ========================
  # Signature
  # ========================

  _attach git_signature_new     => [ 'opaque*', 'string', 'string', 'sint64', 'int' ]                         => 'int';
  _attach git_signature_now      => [ 'opaque*', 'string', 'string' ]                                          => 'int';
  _attach git_signature_default  => [ 'opaque*', 'git_repository' ]                                            => 'int';
  _attach git_signature_free     => [ 'git_signature' ]                                                        => 'void';

  # ========================
  # Remote
  # ========================

  _attach git_remote_lookup           => [ 'opaque*', 'git_repository', 'string' ]                                  => 'int';
  _attach git_remote_create           => [ 'opaque*', 'git_repository', 'string', 'string' ]                        => 'int';
  _attach git_remote_create_anonymous => [ 'opaque*', 'git_repository', 'string' ]                                  => 'int';
  _attach git_remote_url             => [ 'git_remote' ]                                                           => 'string';
  _attach git_remote_name            => [ 'git_remote' ]                                                           => 'string';
  _attach git_remote_init_callbacks   => [ 'opaque', 'uint' ]                                                       => 'int';
  _attach git_fetch_options_init     => [ 'opaque', 'uint' ]                                                       => 'int';
  _attach git_push_options_init       => [ 'opaque', 'uint' ]                                                       => 'int';
  _attach git_remote_fetch           => [ 'git_remote', 'opaque', 'opaque', 'string' ]                             => 'int';
  _attach git_remote_push            => [ 'git_remote', 'opaque', 'opaque' ]                                       => 'int';
  _attach git_remote_connect         => [ 'git_remote', 'int', 'opaque', 'opaque', 'opaque' ]                      => 'int';
  _attach git_remote_ls              => [ 'opaque*', 'size_t*', 'git_remote' ]                                     => 'int';
  _attach git_remote_disconnect       => [ 'git_remote' ]                                                           => 'int';
  _attach git_remote_free             => [ 'git_remote' ]                                                           => 'void';

  # ========================
  # Credentials
  # ========================

  _attach git_credential_userpass_plaintext_new => [ 'opaque*', 'string', 'string' ]                          => 'int';
  _attach git_credential_ssh_key_new           => [ 'opaque*', 'string', 'string', 'string', 'string' ]      => 'int';
  _attach git_credential_ssh_key_from_agent    => [ 'opaque*', 'string' ]                                    => 'int';
  _attach git_credential_default_new           => [ 'opaque*' ]                                              => 'int';
  _attach git_credential_username_new          => [ 'opaque*', 'string' ]                                    => 'int';
  _attach git_credential_free                  => [ 'git_credential' ]                                       => 'void';

  # ========================
  # Clone
  # ========================

  _attach git_clone_options_init => [ 'opaque', 'uint' ]                                                     => 'int';
  _attach git_clone              => [ 'opaque*', 'string', 'string', 'opaque' ]                              => 'int';

  # ========================
  # Strarray
  # ========================

  _attach git_strarray_free => [ 'opaque' ] => 'void';

  # ========================
  # Revwalk
  # ========================

  _attach git_revwalk_new               => [ 'opaque*', 'git_repository' ]                                          => 'int';
  _attach git_revwalk_push              => [ 'git_revwalk', 'opaque' ]                                              => 'int';
  _attach git_revwalk_push_head         => [ 'git_revwalk' ]                                                        => 'int';
  _attach git_revwalk_push_ref          => [ 'git_revwalk', 'string' ]                                              => 'int';
  _attach git_revwalk_push_glob         => [ 'git_revwalk', 'string' ]                                              => 'int';
  _attach git_revwalk_push_range        => [ 'git_revwalk', 'string' ]                                              => 'int';
  _attach git_revwalk_hide             => [ 'git_revwalk', 'opaque' ]                                              => 'int';
  _attach git_revwalk_hide_head        => [ 'git_revwalk' ]                                                        => 'int';
  _attach git_revwalk_hide_ref         => [ 'git_revwalk', 'string' ]                                              => 'int';
  _attach git_revwalk_hide_glob        => [ 'git_revwalk', 'string' ]                                              => 'int';
  _attach git_revwalk_next             => [ 'opaque', 'git_revwalk' ]                                              => 'int';
  _attach git_revwalk_sorting          => [ 'git_revwalk', 'uint' ]                                                => 'int';
  _attach git_revwalk_reset            => [ 'git_revwalk' ]                                                        => 'int';
  _attach git_revwalk_simplify_first_parent => [ 'git_revwalk' ]                                                   => 'int';
  _attach git_revwalk_free             => [ 'git_revwalk' ]                                                        => 'void';

  # ========================
  # Branch
  # ========================

  _attach git_branch_create     => [ 'opaque*', 'git_repository', 'string', 'git_commit', 'int' ]           => 'int';
  _attach git_branch_lookup     => [ 'opaque*', 'git_repository', 'string', 'int' ]                         => 'int';
  _attach git_branch_delete     => [ 'git_reference' ]                                                      => 'int';
  _attach git_branch_iterator_new => [ 'opaque*', 'git_repository', 'int' ]                                   => 'int';
  _attach git_branch_next       => [ 'opaque*', 'int*', 'git_branch_iterator' ]                             => 'int';
  _attach git_branch_iterator_free => [ 'git_branch_iterator' ]                                                => 'void';
  _attach git_branch_name       => [ 'string*', 'git_reference' ]                                           => 'int';
  _attach git_branch_is_head    => [ 'git_reference' ]                                                      => 'int';
  _attach git_branch_move       => [ 'opaque*', 'git_reference', 'string', 'int' ]                          => 'int';

  # ========================
  # Status
  # ========================

  $ffi->type( '(string, uint, opaque)->int' => 'git_status_cb' );
  _attach git_status_options_init => [ 'opaque', 'uint' ]                                                     => 'int';
  _attach git_status_foreach      => [ 'git_repository', 'git_status_cb', 'opaque' ]                          => 'int';
  _attach git_status_foreach_ext  => [ 'git_repository', 'opaque', 'git_status_cb', 'opaque' ]                => 'int';
  _attach git_status_file         => [ 'uint*', 'git_repository', 'string' ]                                  => 'int';

  # ========================
  # Tag
  # ========================

  # oid out-param is a caller-allocated git_oid buffer (opaque), not a
  # pointer-to-pointer - same as the lightweight/from_buffer variants below.
  _attach git_tag_create              => [ 'opaque', 'git_repository', 'string', 'opaque', 'opaque', 'string', 'int' ]  => 'int';
  _attach git_tag_create_from_buffer  => [ 'opaque', 'git_repository', 'string', 'int' ]                            => 'int';
  _attach git_tag_create_lightweight  => [ 'opaque', 'git_repository', 'string', 'git_object', 'int' ]            => 'int';
  _attach git_tag_lookup              => [ 'opaque*', 'git_repository', 'opaque' ]                                => 'int';
  _attach git_tag_delete              => [ 'git_repository', 'string' ]                                           => 'int';
  _attach git_tag_list                => [ 'opaque', 'git_repository' ]                                           => 'int';
  _attach git_tag_list_match          => [ 'opaque', 'string', 'git_repository' ]                                 => 'int';
  _attach git_tag_target              => [ 'opaque*', 'git_tag' ]                                                 => 'int';
  _attach git_tag_target_id           => [ 'git_tag' ]                                                            => 'opaque';
  _attach git_tag_message             => [ 'git_tag' ]                                                            => 'string';
  _attach git_tag_name                => [ 'git_tag' ]                                                            => 'string';
  _attach git_tag_tagger              => [ 'git_tag' ]                                                            => 'opaque';
  _attach git_tag_free                => [ 'git_tag' ]                                                            => 'void';

  # ========================
  # Diff
  # ========================

  _attach git_diff_options_init   => [ 'opaque', 'uint' ]                                                     => 'int';
  _attach git_diff_tree_to_tree   => [ 'opaque*', 'git_repository', 'git_tree', 'git_tree', 'opaque' ]        => 'int';
  _attach git_diff_tree_to_workdir => [ 'opaque*', 'git_repository', 'git_tree', 'opaque' ]                    => 'int';
  _attach git_diff_tree_to_index  => [ 'opaque*', 'git_repository', 'git_tree', 'git_index', 'opaque' ]       => 'int';
  _attach git_diff_index_to_workdir => [ 'opaque*', 'git_repository', 'git_index', 'opaque' ]                   => 'int';
  _attach git_diff_num_deltas     => [ 'git_diff' ]                                                           => 'size_t';
  _attach git_diff_get_delta      => [ 'git_diff', 'size_t' ]                                                 => 'opaque';
  _attach git_diff_free           => [ 'git_diff' ]                                                           => 'void';

  # ========================
  # Index
  # ========================

  _attach git_index_open         => [ 'opaque*', 'string' ]                                                    => 'int';
  _attach git_index_read         => [ 'git_index', 'int' ]                                                     => 'int';
  _attach git_index_write        => [ 'git_index' ]                                                            => 'int';
  _attach git_index_read_tree    => [ 'git_index', 'git_tree' ]                                                => 'int';
  _attach git_index_write_tree  => [ 'opaque', 'git_index' ]                                                  => 'int';
  _attach git_index_add_bypath   => [ 'git_index', 'string' ]                                                  => 'int';
  _attach git_index_add_all      => [ 'git_index', 'opaque', 'uint', 'opaque', 'opaque' ]                       => 'int';
  _attach git_index_remove_bypath => [ 'git_index', 'string' ]                                                 => 'int';
  _attach git_index_clear        => [ 'git_index' ]                                                            => 'int';
  _attach git_index_entrycount   => [ 'git_index' ]                                                            => 'size_t';
  _attach git_index_get_byindex  => [ 'git_index', 'size_t' ]                                                  => 'opaque';
  _attach git_index_find         => [ 'size_t*', 'git_index', 'string' ]                                       => 'int';
  _attach git_index_free         => [ 'git_index' ]                                                            => 'void';

  # ========================
  # Checkout
  # ========================

  _attach git_checkout_options_init => [ 'opaque', 'uint' ]                                                       => 'int';
  _attach git_checkout_head         => [ 'git_repository', 'opaque' ]                                              => 'int';
  _attach git_checkout_index        => [ 'git_repository', 'git_index', 'opaque' ]                                 => 'int';
  _attach git_checkout_tree        => [ 'git_repository', 'git_object', 'opaque' ]                                => 'int';

  # ========================
  # Revparse
  # ========================

  _attach git_revparse_single => [ 'opaque*', 'git_repository', 'string' ]                                  => 'int';
  _attach git_revparse_ext    => [ 'opaque*', 'opaque*', 'git_repository', 'string' ]                        => 'int';

  # ========================
  # Reset
  # ========================

  _attach git_reset         => [ 'git_repository', 'git_object', 'int', 'opaque' ]                        => 'int';
  _attach git_reset_default => [ 'git_repository', 'git_object', 'opaque' ]                               => 'int';

  # ========================
  # Merge
  # ========================

  _attach git_annotated_commit_lookup   => [ 'opaque*', 'git_repository', 'opaque' ]                                => 'int';
  _attach git_annotated_commit_from_ref => [ 'opaque*', 'git_repository', 'git_reference' ]                      => 'int';
  _attach git_annotated_commit_id       => [ 'git_annotated_commit' ]                                              => 'opaque';
  _attach git_annotated_commit_free     => [ 'git_annotated_commit' ]                                               => 'void';
  _attach git_merge_base                => [ 'opaque', 'git_repository', 'opaque', 'opaque' ]                     => 'int';
  _attach git_merge_base_many          => [ 'opaque', 'git_repository', 'uint', 'opaque' ]                     => 'int';
  _attach git_merge_analysis           => [ 'uint*', 'uint*', 'git_repository', 'opaque', 'uint' ]                  => 'int';
  _attach git_merge_options_init       => [ 'opaque', 'uint' ]                                                      => 'int';

  # ========================
  # Graph
  # ========================

  _attach git_graph_ahead_behind  => [ 'size_t*', 'size_t*', 'git_repository', 'opaque', 'opaque' ]            => 'int';
  _attach git_graph_descendant_of => [ 'git_repository', 'opaque', 'opaque' ]                                  => 'int';

  # ========================
  # Stash
  # ========================

  _attach git_stash_save   => [ 'opaque*', 'git_repository', 'git_signature', 'string', 'uint' ]        => 'int';
  _attach git_stash_apply  => [ 'git_repository', 'size_t', 'opaque' ]                                   => 'int';
  _attach git_stash_drop  => [ 'git_repository', 'size_t' ]                                             => 'int';

  # ========================
  # Reflog
  # ========================

  _attach git_reflog_read          => [ 'opaque*', 'git_repository', 'string' ]                                  => 'int';
  _attach git_reflog_entrycount    => [ 'git_reflog' ]                                                           => 'size_t';
  _attach git_reflog_entry_byindex => [ 'git_reflog', 'size_t' ]                                                 => 'opaque';
  _attach git_reflog_entry_id_new  => [ 'git_reflog_entry' ]                                                  => 'opaque';
  _attach git_reflog_entry_message => [ 'git_reflog_entry' ]                                                  => 'string';
  _attach git_reflog_free          => [ 'git_reflog' ]                                                           => 'void';

  # ========================
  # Rebase
  # ========================

  _attach git_rebase_init                 => [ 'opaque*', 'git_repository', 'git_annotated_commit', 'git_annotated_commit', 'git_annotated_commit', 'opaque' ] => 'int';
  _attach git_rebase_open                 => [ 'opaque*', 'git_repository', 'opaque' ]                                  => 'int';
  _attach git_rebase_next                 => [ 'opaque*', 'git_rebase' ]                                               => 'int';
  _attach git_rebase_commit               => [ 'opaque', 'git_rebase', 'git_signature', 'git_signature', 'string', 'string' ] => 'int';
  _attach git_rebase_abort                => [ 'git_rebase' ]                                                           => 'int';
  _attach git_rebase_finish               => [ 'git_rebase', 'git_signature' ]                                          => 'int';
  _attach git_rebase_free                 => [ 'git_rebase' ]                                                           => 'void';
  _attach git_rebase_operation_entrycount => [ 'git_rebase' ]                                                    => 'size_t';
  _attach git_rebase_operation_current    => [ 'git_rebase' ]                                                    => 'size_t';
  _attach git_rebase_operation_byindex    => [ 'git_rebase', 'size_t' ]                                          => 'opaque';
  _attach git_rebase_options_init         => [ 'opaque', 'uint' ]                                                      => 'int';
  _attach git_rebase_orig_head_name       => [ 'git_rebase' ]                                                          => 'string';
  _attach git_rebase_orig_head_id         => [ 'git_rebase' ]                                                          => 'opaque';
  _attach git_rebase_onto_name           => [ 'git_rebase' ]                                                          => 'string';
  _attach git_rebase_onto_id             => [ 'git_rebase' ]                                                          => 'opaque';

  # ========================
  # Cherry-pick
  # ========================

  _attach git_cherrypick            => [ 'git_repository', 'git_commit', 'opaque' ]                              => 'int';
  _attach git_cherrypick_commit     => [ 'opaque*', 'git_repository', 'git_commit', 'git_commit', 'uint', 'opaque' ] => 'int';
  _attach git_cherrypick_options_init => [ 'opaque', 'uint' ]                                                   => 'int';

  # ========================
  # Revert
  # ========================

  _attach git_revert              => [ 'git_repository', 'git_commit', 'opaque' ]                               => 'int';
  _attach git_revert_commit       => [ 'opaque*', 'git_repository', 'git_commit', 'git_commit', 'uint', 'opaque' ] => 'int';
  _attach git_revert_options_init => [ 'opaque', 'uint' ]                                                       => 'int';

  # ========================
  # ODB
  # ========================

  _attach git_odb_new    => [ 'opaque*', 'git_repository' ]                                          => 'int';
  _attach git_odb_exists => [ 'git_odb', 'opaque' ]                                                  => 'int';
  _attach git_odb_free   => [ 'git_odb' ]                                                            => 'void';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Libgit2::FFI - Internal FFI::Platypus instance for Git::Libgit2

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  use Git::Libgit2::FFI;
  my $ffi = Git::Libgit2::FFI::ffi();

=head1 DESCRIPTION

Internal use only. Holds the singleton C<FFI::Platypus> instance with all
attached libgit2 functions. Consumers should use L<Git::Libgit2> instead.

This module is a thin FFI layer over libgit2. All functions follow the libgit2
C API naming and signatures as closely as possible. Return codes must be checked
with C<Git::Libgit2::check_rc>. Every C<*_new> / C<*_lookup> must be matched with
its C<*_free> call.

=head2 ffi

    my $ffi = Git::Libgit2::FFI::ffi();

Return the process-wide singleton C<FFI::Platypus> instance, building it on the
first call: it opens the L<Alien::Libgit2> dynamic library, registers the
libgit2 opaque types and callback signatures, and attaches every bound
function. Internal — consumers should use L<Git::Libgit2> instead.

=head1 GROUPS

=head2 Library Init / Shutdown

=head2 git_libgit2_init

    my $rc = Git::Libgit2::FFI::git_libgit2_init();

Initialise the libgit2 library. Returns the new reference count (call
C<shutdown_lib> once per init).

=head2 git_libgit2_shutdown

    my $rc = Git::Libgit2::FFI::git_libgit2_shutdown();

Decrement the libgit2 reference count. Returns the remaining count.

=head2 git_libgit2_version

    Git::Libgit2::FFI::git_libgit2_version(\my $maj, \my $min, \my $rev);

Store the library version into the three Integer references.

=head2 Error

=head2 git_error_last

    my $err = Git::Libgit2::FFI::git_error_last();

Return the current thread-local error struct pointer.

=head2 git_error_clear

    Git::Libgit2::FFI::git_error_clear();

Clear the current thread-local error state.

=head2 Repository

=head2 git_repository_open

    Git::Libgit2::FFI::git_repository_open(\my $repo, '/path/to/.git');

Open a repository at the given path. Free with C<git_repository_free>.

=head2 git_repository_open_ext

    Git::Libgit2::FFI::git_repository_open_ext(\my $repo, $path, $flags, $ceiled_paths);

Open a repository with extended options. See libgit2 docs for flag values.

=head2 git_repository_init

    Git::Libgit2::FFI::git_repository_init(\my $repo, '/path/to/create', $flags);

Create a new repository. Free with C<git_repository_free>.

=head2 git_repository_set_head

    Git::Libgit2::FFI::git_repository_set_head($repo, 'refs/heads/main');

Make HEAD point at the given reference. The reference need not exist yet
(an unborn branch is valid), so this is the way to pin the initial branch
of a freshly C<git_repository_init>'d repo instead of relying on libgit2's
compiled-in default (C<master>) or the ambient C<init.defaultBranch> config.

=head2 git_repository_head

    Git::Libgit2::FFI::git_repository_head(\my $ref, $repo);

Retrieve and resolve the reference pointed at by HEAD. Free the returned
reference with C<git_reference_free>. Returns C<GIT_EUNBORNBRANCH> when HEAD
points at a branch with no commits yet, or C<GIT_ENOTFOUND> when HEAD is
missing.

=head2 git_repository_head_unborn

    my $unborn = Git::Libgit2::FFI::git_repository_head_unborn($repo);

Return true (1) if HEAD points at a branch that does not exist yet (a fresh
repo before its first commit), false (0) otherwise.

=head2 git_repository_head_detached

    my $detached = Git::Libgit2::FFI::git_repository_head_detached($repo);

Return true (1) if HEAD is detached — i.e. it points directly at a commit
rather than at a branch reference.

=head2 git_repository_workdir

    my $dir = Git::Libgit2::FFI::git_repository_workdir($repo);

Return the working directory path (or C<undef> for bare repos).

=head2 git_repository_path

    my $path = Git::Libgit2::FFI::git_repository_path($repo);

Return the C<.git> directory path.

=head2 git_repository_is_bare

    my $is_bare = Git::Libgit2::FFI::git_repository_is_bare($repo);

Returns true if the repository is bare.

=head2 git_repository_free

    Git::Libgit2::FFI::git_repository_free($repo);

Free the repository handle.

=head2 git_repository_index

    Git::Libgit2::FFI::git_repository_index(\my $index, $repo);

Get the repository's index. Free with C<git_index_free>.

=head2 git_repository_config

    Git::Libgit2::FFI::git_repository_config(\my $config, $repo);

Get the repository's config. Free with C<git_config_free>.

=head2 git_repository_config_snapshot

    Git::Libgit2::FFI::git_repository_config_snapshot(\my $config, $repo);

Get a snapshot of the repository's config. Free with C<git_config_free>.

=head2 git_repository_odb

    Git::Libgit2::FFI::git_repository_odb(\my $odb, $repo);

Get the repository's object database. Free with C<git_odb_free>.

=head2 Config

=head2 git_config_open_default

    Git::Libgit2::FFI::git_config_open_default(\my $config);

Open the global / XDG config. Free with C<git_config_free>.

=head2 git_config_snapshot

    Git::Libgit2::FFI::git_config_snapshot(\my $snapshot, $config);

Create a snapshot of a config. Free with C<git_config_free>.

=head2 git_config_get_string

    Git::Libgit2::FFI::git_config_get_string(\my $str, $config, $key);

Read a string config value.

=head2 git_config_set_string

    Git::Libgit2::FFI::git_config_set_string($config, $key, $value);

Write a string config value.

=head2 git_config_free

    Git::Libgit2::FFI::git_config_free($config);

Free the config handle.

=head2 OID

=head2 git_oid_fromstr

    Git::Libgit2::FFI::git_oid_fromstr($oid_ptr, '40-char-hex');

Parse a hex string into an OID buffer.

=head2 git_oid_tostr

    Git::Libgit2::FFI::git_oid_tostr($buf_ptr, 41, $oid_ptr);

Write the OID as a 40-char hex string into the buffer.

=head2 git_oid_cmp

    my $cmp = Git::Libgit2::FFI::git_oid_cmp($oid_a, $oid_b);

Compare two OIDs. Returns <0, 0, or >0.

=head2 Reference

=head2 git_reference_lookup

    Git::Libgit2::FFI::git_reference_lookup(\my $ref, $repo, 'refs/heads/main');

Look up a reference by name. Free with C<git_reference_free>.

=head2 git_reference_name_to_id

    Git::Libgit2::FFI::git_reference_name_to_id($oid_ptr, $repo, 'refs/heads/main');

Resolve a reference name to an OID.

=head2 git_reference_create

    Git::Libgit2::FFI::git_reference_create(\my $ref, $repo, 'refs/heads/main', $oid_ptr, $force, $log_message);

Create or update a direct reference. Free with C<git_reference_free>.

=head2 git_reference_delete

    Git::Libgit2::FFI::git_reference_delete($ref);

Delete the reference.

=head2 git_reference_remove

    Git::Libgit2::FFI::git_reference_remove($repo, 'refs/heads/main');

Remove a reference by name.

=head2 git_reference_target

    my $target = Git::Libgit2::FFI::git_reference_target($ref);

Get the target OID of a reference (must be direct).

=head2 git_reference_name

    my $name = Git::Libgit2::FFI::git_reference_name($ref);

Get the full name of the reference.

=head2 git_reference_type

    my $type = Git::Libgit2::FFI::git_reference_type($ref);

Get the reference type (C<GIT_REFERENCE_DIRECT> or C<GIT_REFERENCE_SYMBOLIC>).

=head2 git_reference_free

    Git::Libgit2::FFI::git_reference_free($ref);

Free the reference handle.

=head2 git_reference_iterator_new

    Git::Libgit2::FFI::git_reference_iterator_new(\my $iter, $repo);

Create an iterator over all references. Free with C<git_reference_iterator_free>.

=head2 git_reference_iterator_glob_new

    Git::Libgit2::FFI::git_reference_iterator_glob_new(\my $iter, $repo, 'refs/remotes/*');

Create an iterator over references matching a glob pattern. Free with C<git_reference_iterator_free>.

=head2 git_reference_next

    Git::Libgit2::FFI::git_reference_next(\my $ref, $iter);

Return the next reference (ordered). Free with C<git_reference_free>.

=head2 git_reference_next_name

    Git::Libgit2::FFI::git_reference_next_name(\my $name, $iter);

Return the next reference name as a string.

=head2 git_reference_iterator_free

    Git::Libgit2::FFI::git_reference_iterator_free($iter);

Free the iterator.

=head2 git_reference_name_is_valid

    Git::Libgit2::FFI::git_reference_name_is_valid(\my $valid, $name);

Check if a reference name is valid.

=head2 git_reference_peel

    Git::Libgit2::FFI::git_reference_peel(\my $obj, $ref, $type);

Peel a reference to the underlying object of the given type. Free the object with C<git_object_free>.

=head2 git_reference_symbolic_create

    Git::Libgit2::FFI::git_reference_symbolic_create(\my $ref, $repo, 'HEAD', 'refs/heads/main', $force, $log_message);

Create or update a symbolic reference pointing at C<$target>. Free with
C<git_reference_free>.

=head2 git_reference_symbolic_target

    my $target = Git::Libgit2::FFI::git_reference_symbolic_target($ref);

Return the target name of a symbolic reference (C<undef> for direct refs).

=head2 git_reference_symbolic_set_target

    Git::Libgit2::FFI::git_reference_symbolic_set_target(\my $new_ref, $ref, 'refs/heads/main', $log_message);

Create a new reference with the same name as C<$ref> but a new symbolic
target. Free the result with C<git_reference_free>.

=head2 git_reference_set_target

    Git::Libgit2::FFI::git_reference_set_target(\my $new_ref, $ref, $oid_ptr, $log_message);

Create a new reference with the same name as C<$ref> but pointing at a new
OID target. Free the result with C<git_reference_free>.

=head2 git_reference_resolve

    Git::Libgit2::FFI::git_reference_resolve(\my $resolved, $ref);

Resolve a symbolic reference to a direct reference. Free with
C<git_reference_free>.

=head2 git_reference_shorthand

    my $short = Git::Libgit2::FFI::git_reference_shorthand($ref);

Return the human-friendly short name of the reference (e.g. C<main> instead
of C<refs/heads/main>).

=head2 git_reference_is_branch

    my $is_branch = Git::Libgit2::FFI::git_reference_is_branch($ref);

Return true if the reference lives under C<refs/heads/>.

=head2 git_reference_is_remote

    my $is_remote = Git::Libgit2::FFI::git_reference_is_remote($ref);

Return true if the reference lives under C<refs/remotes/>.

=head2 git_reference_is_tag

    my $is_tag = Git::Libgit2::FFI::git_reference_is_tag($ref);

Return true if the reference lives under C<refs/tags/>.

=head2 Object

=head2 git_object_lookup

    Git::Libgit2::FFI::git_object_lookup(\my $obj, $repo, $oid_ptr, $type);

Look up any object by OID. Free with C<git_object_free>.

=head2 git_object_id

    my $oid = Git::Libgit2::FFI::git_object_id($obj);

Get the OID of an object.

=head2 git_object_type

    my $type = Git::Libgit2::FFI::git_object_type($obj);

Get the type of an object.

=head2 git_object_free

    Git::Libgit2::FFI::git_object_free($obj);

Free the object handle.

=head2 Blob

=head2 git_blob_create_from_buffer

    Git::Libgit2::FFI::git_blob_create_from_buffer($oid_ptr, $repo, $content_ptr, $len);

Create a blob from a memory buffer. C<$content_ptr> must be a C<scalar_to_buffer>
result. Returns the OID of the created blob.

=head2 git_blob_lookup

    Git::Libgit2::FFI::git_blob_lookup(\my $blob, $repo, $oid_ptr);

Look up a blob by OID. Free with C<git_blob_free>.

=head2 git_blob_rawcontent

    my $ptr = Git::Libgit2::FFI::git_blob_rawcontent($blob);

Return a pointer to the raw blob content. The memory is owned by the blob —
do not free it.

=head2 git_blob_rawsize

    my $size = Git::Libgit2::FFI::git_blob_rawsize($blob);

Return the size of the blob content in bytes.

=head2 git_blob_is_binary

    my $is_binary = Git::Libgit2::FFI::git_blob_is_binary($blob);

Return true if the blob appears to be binary data.

=head2 git_blob_free

    Git::Libgit2::FFI::git_blob_free($blob);

Free the blob handle.

=head2 Tree

=head2 git_tree_lookup

    Git::Libgit2::FFI::git_tree_lookup(\my $tree, $repo, $oid_ptr);

Look up a tree by OID. Free with C<git_tree_free>.

=head2 git_tree_entrycount

    my $count = Git::Libgit2::FFI::git_tree_entrycount($tree);

Return the number of entries in the tree.

=head2 git_tree_entry_byindex

    my $entry = Git::Libgit2::FFI::git_tree_entry_byindex($tree, $idx);

Return the entry at the given index (0-based).

=head2 git_tree_entry_byname

    my $entry = Git::Libgit2::FFI::git_tree_entry_byname($tree, $filename);

Return the entry with the given filename.

=head2 git_tree_entry_name

    my $name = Git::Libgit2::FFI::git_tree_entry_name($entry);

Return the entry filename.

=head2 git_tree_entry_id

    my $oid = Git::Libgit2::FFI::git_tree_entry_id($entry);

Return the entry OID.

=head2 git_tree_entry_filemode

    my $mode = Git::Libgit2::FFI::git_tree_entry_filemode($entry);

Return the file mode of the entry.

=head2 git_tree_entry_type

    my $type = Git::Libgit2::FFI::git_tree_entry_type($entry);

Return the object type of the entry (C<GIT_OBJECT_BLOB>, etc.).

=head2 git_tree_free

    Git::Libgit2::FFI::git_tree_free($tree);

Free the tree handle.

=head2 TreeBuilder

=head2 git_treebuilder_new

    Git::Libgit2::FFI::git_treebuilder_new(\my $tb, $repo, $tree);  # tree may be undef

Create a new tree builder, optionally from an existing tree. Free with C<git_treebuilder_free>.

=head2 git_treebuilder_insert

    Git::Libgit2::FFI::git_treebuilder_insert(\my $entry, $tb, $filename, $oid_ptr, $filemode);

Insert an entry into the builder.

=head2 git_treebuilder_remove

    Git::Libgit2::FFI::git_treebuilder_remove($tb, $filename);

Remove an entry from the builder.

=head2 git_treebuilder_write

    Git::Libgit2::FFI::git_treebuilder_write($oid_ptr, $tb);

Write the tree and return its OID.

=head2 git_treebuilder_free

    Git::Libgit2::FFI::git_treebuilder_free($tb);

Free the tree builder.

=head2 Commit

=head2 git_commit_lookup

    Git::Libgit2::FFI::git_commit_lookup(\my $commit, $repo, $oid_ptr);

Look up a commit by OID. Free with C<git_commit_free>.

=head2 git_commit_create

    Git::Libgit2::FFI::git_commit_create($oid_ptr, $repo, $ref_name, $author_sig, $committer_sig, $encoding, $message, $tree, $parent_count, $parents);

Create a commit. C<$parents> is passed as C<undef> when C<$parent_count> is 0.

=head2 git_commit_message

    my $msg = Git::Libgit2::FFI::git_commit_message($commit);

Return the commit message.

=head2 git_commit_tree

    Git::Libgit2::FFI::git_commit_tree(\my $tree, $commit);

Get the tree of a commit. Free with C<git_tree_free>.

=head2 git_commit_tree_id

    my $oid = Git::Libgit2::FFI::git_commit_tree_id($commit);

Get the tree OID of a commit.

=head2 git_commit_parentcount

    my $n = Git::Libgit2::FFI::git_commit_parentcount($commit);

Return the number of parents of the commit.

=head2 git_commit_parent_id

    my $oid = Git::Libgit2::FFI::git_commit_parent_id($commit, $n);

Return the OID of the N-th parent (0-based).

=head2 git_commit_author

    my $sig = Git::Libgit2::FFI::git_commit_author($commit);

Return the author signature (C<git_signature*>). Do not free.

=head2 git_commit_committer

    my $sig = Git::Libgit2::FFI::git_commit_committer($commit);

Return the committer signature (C<git_signature*>). Do not free.

=head2 git_commit_id

    my $oid = Git::Libgit2::FFI::git_commit_id($commit);

Return the OID of the commit (C<const git_oid *>). Do not free.

=head2 git_commit_time

    my $epoch = Git::Libgit2::FFI::git_commit_time($commit);

Return the commit time as a Unix timestamp (seconds since the epoch).

=head2 git_commit_time_offset

    my $offset = Git::Libgit2::FFI::git_commit_time_offset($commit);

Return the commit's timezone offset in minutes from UTC.

=head2 git_commit_summary

    my $summary = Git::Libgit2::FFI::git_commit_summary($commit);

Return the short summary of the commit message (the first paragraph / first
line).

=head2 git_commit_free

    Git::Libgit2::FFI::git_commit_free($commit);

Free the commit handle.

=head2 Signature

=head2 git_signature_new

    Git::Libgit2::FFI::git_signature_new(\my $sig, $name, $email, $time_t, $offset);

Create a signature. Free with C<git_signature_free>.

=head2 git_signature_now

    Git::Libgit2::FFI::git_signature_now(\my $sig, $name, $email);

Create a signature with the current time. Free with C<git_signature_free>.

=head2 git_signature_default

    Git::Libgit2::FFI::git_signature_default(\my $sig, $repo);

Create a signature from the repository config. Free with C<git_signature_free>.

=head2 git_signature_free

    Git::Libgit2::FFI::git_signature_free($sig);

Free the signature handle.

=head2 Remote

=head2 git_remote_lookup

    Git::Libgit2::FFI::git_remote_lookup(\my $remote, $repo, $name);

Look up a remote by name. Free with C<git_remote_free>.

=head2 git_remote_create

    Git::Libgit2::FFI::git_remote_create(\my $remote, $repo, $name, $url);

Create a remote. Free with C<git_remote_free>.

=head2 git_remote_create_anonymous

    Git::Libgit2::FFI::git_remote_create_anonymous(\my $remote, $repo, $url);

Create an anonymous remote from a URL. Free with C<git_remote_free>.

=head2 git_remote_url

    my $url = Git::Libgit2::FFI::git_remote_url($remote);

Return the URL of the remote.

=head2 git_remote_name

    my $name = Git::Libgit2::FFI::git_remote_name($remote);

Return the name of the remote.

=head2 git_remote_init_callbacks

    Git::Libgit2::FFI::git_remote_init_callbacks($callbacks_ptr, $version);

Initialize callbacks struct for remote operations.

=head2 git_remote_fetch

    Git::Libgit2::FFI::git_remote_fetch($remote, $refspecs, $options, $reflog_msg);

Fetch using the remote. See also C<git_fetch_options_init>.

=head2 git_remote_push

    Git::Libgit2::FFI::git_remote_push($remote, $refspecs, $options);

Push using the remote. See also C<git_push_options_init>.

=head2 git_remote_connect

    Git::Libgit2::FFI::git_remote_connect($remote, $direction, $callbacks, $options, $resolved_url);

Connect to the remote.

=head2 git_remote_ls

    Git::Libgit2::FFI::git_remote_ls(\my $heads, \my $len, $remote);

List remote branches. C<$heads> is an array of OID pointers.

=head2 git_remote_disconnect

    Git::Libgit2::FFI::git_remote_disconnect($remote);

Disconnect from the remote.

=head2 git_remote_free

    Git::Libgit2::FFI::git_remote_free($remote);

Free the remote handle.

=head2 Credentials

=head2 git_credential_userpass_plaintext_new

    Git::Libgit2::FFI::git_credential_userpass_plaintext_new(\my $cred, $username, $password);

Create a username/password credential.

=head2 git_credential_ssh_key_new

    Git::Libgit2::FFI::git_credential_ssh_key_new(\my $cred, $username, $public_key, $private_key, $passphrase);

Create an SSH key credential.

=head2 git_credential_ssh_key_from_agent

    Git::Libgit2::FFI::git_credential_ssh_key_from_agent(\my $cred, $username);

Create an SSH key credential using the ssh-agent.

=head2 git_credential_default_new

    Git::Libgit2::FFI::git_credential_default_new(\my $cred);

Create a default credential (e.g. from GIT_ASKPASS).

=head2 git_credential_username_new

    Git::Libgit2::FFI::git_credential_username_new(\my $cred, $username);

Create a username-only credential.

=head2 git_credential_free

    Git::Libgit2::FFI::git_credential_free($cred);

Free the credential handle.

=head2 Clone

=head2 git_clone_options_init

    Git::Libgit2::FFI::git_clone_options_init($opts_ptr, $version);

Initialize clone options struct.

=head2 git_clone

    Git::Libgit2::FFI::git_clone(\my $repo, $url, $path, $opts);

Clone a repository. Free the repo with C<git_repository_free>.

=head2 Strarray

=head2 git_strarray_free

    Git::Libgit2::FFI::git_strarray_free($strarray);

Free a strarray (used by tag list, branch list iteration, etc.).

=head2 Revwalk

=head2 git_revwalk_new

    Git::Libgit2::FFI::git_revwalk_new(\my $walk, $repo);

Create a revision walker. Free with C<git_revwalk_free>.

=head2 git_revwalk_push

    Git::Libgit2::FFI::git_revwalk_push($walk, $oid_ptr);

Push a commit OID to start walking from.

=head2 git_revwalk_push_head

    Git::Libgit2::FFI::git_revwalk_push_head($walk);

Push HEAD to start walking from.

=head2 git_revwalk_push_ref

    Git::Libgit2::FFI::git_revwalk_push_ref($walk, $refname);

Push a reference to start walking from.

=head2 git_revwalk_push_glob

    Git::Libgit2::FFI::git_revwalk_push_glob($walk, $glob);

Push all references matching a glob.

=head2 git_revwalk_push_range

    Git::Libgit2::FFI::git_revwalk_push_range($walk, $range);

Push a commit range (C<from..to>).

=head2 git_revwalk_hide

    Git::Libgit2::FFI::git_revwalk_hide($walk, $oid_ptr);

Hide a commit OID (stop walking at this point).

=head2 git_revwalk_hide_head

    Git::Libgit2::FFI::git_revwalk_hide_head($walk);

Hide HEAD.

=head2 git_revwalk_hide_ref

    Git::Libgit2::FFI::git_revwalk_hide_ref($walk, $refname);

Hide a reference.

=head2 git_revwalk_hide_glob

    Git::Libgit2::FFI::git_revwalk_hide_glob($walk, $glob);

Hide all references matching a glob.

=head2 git_revwalk_next

    Git::Libgit2::FFI::git_revwalk_next($oid_ptr, $walk);

Get the next commit OID in the walk.

=head2 git_revwalk_sorting

    Git::Libgit2::FFI::git_revwalk_sorting($walk, $sort_mode);

Set the sorting mode (C<GIT_SORT_NONE>, C<GIT_SORT_TOPOLOGICAL>, etc.).

=head2 git_revwalk_reset

    Git::Libgit2::FFI::git_revwalk_reset($walk);

Reset the walker for a new traversal.

=head2 git_revwalk_simplify_first_parent

    Git::Libgit2::FFI::git_revwalk_simplify_first_parent($walk);

Simplify the walk to first-parent only.

=head2 git_revwalk_free

    Git::Libgit2::FFI::git_revwalk_free($walk);

Free the revision walker.

=head2 Branch

=head2 git_branch_create

    Git::Libgit2::FFI::git_branch_create(\my $ref, $repo, $name, $commit, $force);

Create a new branch. Free with C<git_reference_free>.

=head2 git_branch_lookup

    Git::Libgit2::FFI::git_branch_lookup(\my $ref, $repo, $name, $branch_type);

Look up a branch by name. Free with C<git_reference_free>.

=head2 git_branch_delete

    Git::Libgit2::FFI::git_branch_delete($ref);

Delete the branch reference.

=head2 git_branch_iterator_new

    Git::Libgit2::FFI::git_branch_iterator_new(\my $iter, $repo, $filter);

Create a branch iterator. Free with C<git_branch_iterator_free>.

=head2 git_branch_next

    Git::Libgit2::FFI::git_branch_next(\my $ref, \my $type, $iter);

Get the next branch. Free with C<git_reference_free>.

=head2 git_branch_iterator_free

    Git::Libgit2::FFI::git_branch_iterator_free($iter);

Free the branch iterator.

=head2 git_branch_name

    Git::Libgit2::FFI::git_branch_name(\my $name, $ref);

Get the branch name from a reference.

=head2 git_branch_is_head

    my $is_head = Git::Libgit2::FFI::git_branch_is_head($ref);

Return true if the branch is HEAD.

=head2 git_branch_move

    Git::Libgit2::FFI::git_branch_move(\my $new_ref, $ref, $new_name, $force);

Rename a branch. Free with C<git_reference_free>.

=head2 Status

=head2 git_status_options_init

    Git::Libgit2::FFI::git_status_options_init($opts_ptr, $version);

Initialize status options struct.

=head2 git_status_foreach

    Git::Libgit2::FFI::git_status_foreach($repo, $callback, $payload);

Run a callback for each status entry. The callback receives C<(path, flags, payload)>.

=head2 git_status_foreach_ext

    Git::Libgit2::FFI::git_status_foreach_ext($repo, $opts, $callback, $payload);

Like C<git_status_foreach> but with extended options.

=head2 git_status_file

    Git::Libgit2::FFI::git_status_file(\my $flags, $repo, $path);

Get the status flags for a single file.

=head2 Tag

=head2 git_tag_create

    Git::Libgit2::FFI::git_tag_create(\my $tag, $repo, $tag_name, $target, $tagger, $message, $force);

Create an annotated tag. Free with C<git_tag_free>.

=head2 git_tag_create_from_buffer

    Git::Libgit2::FFI::git_tag_create_from_buffer($oid_ptr, $repo, $buffer, $force);

Create a tag from a buffer.

=head2 git_tag_create_lightweight

    Git::Libgit2::FFI::git_tag_create_lightweight($oid_ptr, $repo, $name, $target, $force);

Create a lightweight tag.

=head2 git_tag_lookup

    Git::Libgit2::FFI::git_tag_lookup(\my $tag, $repo, $oid_ptr);

Look up a tag by OID. Free with C<git_tag_free>.

=head2 git_tag_delete

    Git::Libgit2::FFI::git_tag_delete($repo, $tag_name);

Delete a tag.

=head2 git_tag_list

    Git::Libgit2::FFI::git_tag_list($strarray, $repo);

List all tags into a strarray. Free with C<git_strarray_free>.

=head2 git_tag_list_match

    Git::Libgit2::FFI::git_tag_list_match($strarray, $pattern, $repo);

List tags matching a pattern. Free with C<git_strarray_free>.

=head2 git_tag_target

    Git::Libgit2::FFI::git_tag_target(\my $obj, $tag);

Get the target object of a tag. Free with C<git_object_free>.

=head2 git_tag_target_id

    my $oid = Git::Libgit2::FFI::git_tag_target_id($tag);

Get the target OID of a tag.

=head2 git_tag_message

    my $msg = Git::Libgit2::FFI::git_tag_message($tag);

Return the tag message.

=head2 git_tag_name

    my $name = Git::Libgit2::FFI::git_tag_name($tag);

Return the tag name.

=head2 git_tag_tagger

    my $sig = Git::Libgit2::FFI::git_tag_tagger($tag);

Return the tagger signature.

=head2 git_tag_free

    Git::Libgit2::FFI::git_tag_free($tag);

Free the tag handle.

=head2 Diff

=head2 git_diff_options_init

    Git::Libgit2::FFI::git_diff_options_init($opts_ptr, $version);

Initialize diff options struct.

=head2 git_diff_tree_to_tree

    Git::Libgit2::FFI::git_diff_tree_to_tree(\my $diff, $repo, $old_tree, $new_tree, $opts);

Diff two trees. Free with C<git_diff_free>.

=head2 git_diff_tree_to_workdir

    Git::Libgit2::FFI::git_diff_tree_to_workdir(\my $diff, $repo, $tree, $opts);

Diff a tree against the working directory. Free with C<git_diff_free>.

=head2 git_diff_tree_to_index

    Git::Libgit2::FFI::git_diff_tree_to_index(\my $diff, $repo, $tree, $index, $opts);

Diff a tree against the index. Free with C<git_diff_free>.

=head2 git_diff_index_to_workdir

    Git::Libgit2::FFI::git_diff_index_to_workdir(\my $diff, $repo, $index, $opts);

Diff the index against the working directory. Free with C<git_diff_free>.

=head2 git_diff_num_deltas

    my $n = Git::Libgit2::FFI::git_diff_num_deltas($diff);

Return the number of deltas in the diff.

=head2 git_diff_get_delta

    my $delta = Git::Libgit2::FFI::git_diff_get_delta($diff, $idx);

Return the delta at the given index.

=head2 git_diff_free

    Git::Libgit2::FFI::git_diff_free($diff);

Free the diff handle.

=head2 Index

=head2 git_index_open

    Git::Libgit2::FFI::git_index_open(\my $index, $index_path);

Open an index file. Free with C<git_index_free>.

=head2 git_index_read

    Git::Libgit2::FFI::git_index_read($index, $force);

Read (reload) the index from disk.

=head2 git_index_write

    Git::Libgit2::FFI::git_index_write($index);

Write the index to disk.

=head2 git_index_read_tree

    Git::Libgit2::FFI::git_index_read_tree($index, $tree);

Read a tree into the index.

=head2 git_index_write_tree

    Git::Libgit2::FFI::git_index_write_tree($oid_ptr, $index);

Write the index as a tree to the object database.

=head2 git_index_add_bypath

    Git::Libgit2::FFI::git_index_add_bypath($index, $path);

Add a file at the given path to the index.

=head2 git_index_add_all

    Git::Libgit2::FFI::git_index_add_all($index, $pathspecs, $flags, $callback, $payload);

Add all files matching pathspecs to the index.

=head2 git_index_remove_bypath

    Git::Libgit2::FFI::git_index_remove_bypath($index, $path);

Remove an entry from the index by path.

=head2 git_index_clear

    Git::Libgit2::FFI::git_index_clear($index);

Clear the index.

=head2 git_index_entrycount

    my $n = Git::Libgit2::FFI::git_index_entrycount($index);

Return the number of entries in the index.

=head2 git_index_get_byindex

    my $entry = Git::Libgit2::FFI::git_index_get_byindex($index, $idx);

Return the entry at the given index.

=head2 git_index_find

    Git::Libgit2::FFI::git_index_find(\my $pos, $index, $path);

Find the position of an entry by path. Returns C<UINT_MAX> if not found.

=head2 git_index_free

    Git::Libgit2::FFI::git_index_free($index);

Free the index handle.

=head2 Checkout

=head2 git_checkout_options_init

    Git::Libgit2::FFI::git_checkout_options_init($opts_ptr, $version);

Initialize checkout options struct.

=head2 git_checkout_head

    Git::Libgit2::FFI::git_checkout_head($repo, $opts);

Checkout HEAD to the working directory.

=head2 git_checkout_index

    Git::Libgit2::FFI::git_checkout_index($repo, $index, $opts);

Checkout the index (or a given tree) to the working directory.

=head2 git_checkout_tree

    Git::Libgit2::FFI::git_checkout_tree($repo, $obj, $opts);

Checkout an arbitrary treeish object to the working directory.

=head2 Revparse

=head2 git_revparse_single

    Git::Libgit2::FFI::git_revparse_single(\my $obj, $repo, $spec);

Resolve a revision spec to a single object. Free with C<git_object_free>.

=head2 git_revparse_ext

    Git::Libgit2::FFI::git_revparse_ext(\my $obj, \my $ref, $repo, $spec);

Resolve a revision spec to an object and its reference.

=head2 Reset

=head2 git_reset

    Git::Libgit2::FFI::git_reset($repo, $obj, $reset_type, $opts);

Reset a repository to a given state.

=head2 git_reset_default

    Git::Libgit2::FFI::git_reset_default($repo, $obj, $opts);

Reset specific paths in the index.

=head2 Merge

=head2 git_annotated_commit_lookup

    Git::Libgit2::FFI::git_annotated_commit_lookup(\my $ann, $repo, $oid_ptr);

Look up an annotated commit. Free with C<git_annotated_commit_free>.

=head2 git_annotated_commit_from_ref

    Git::Libgit2::FFI::git_annotated_commit_from_ref(\my $ann, $repo, $ref);

Create an annotated commit from a reference. Free with C<git_annotated_commit_free>.

=head2 git_annotated_commit_id

    my $oid = Git::Libgit2::FFI::git_annotated_commit_id($ann);

Get the OID of an annotated commit.

=head2 git_annotated_commit_free

    Git::Libgit2::FFI::git_annotated_commit_free($ann);

Free the annotated commit handle.

=head2 git_merge_base

    Git::Libgit2::FFI::git_merge_base($oid_ptr, $repo, $a, $b);

Find the merge base of two commits.

=head2 git_merge_base_many

    Git::Libgit2::FFI::git_merge_base_many($oid_ptr, $repo, $n, $tips);

Find the merge base of many commits.

=head2 git_merge_analysis

    Git::Libgit2::FFI::git_merge_analysis(\my $analysis, \my $preference, $repo, $ann, $n);

Analyze a merge situation.

=head2 git_merge_options_init

    Git::Libgit2::FFI::git_merge_options_init($opts_ptr, $version);

Initialize merge options struct.

=head2 Graph

=head2 git_graph_ahead_behind

    Git::Libgit2::FFI::git_graph_ahead_behind(\my $ahead, \my $behind, $repo, $local, $upstream);

Count commits that are ahead and behind a given commit.

=head2 git_graph_descendant_of

    my $is_desc = Git::Libgit2::FFI::git_graph_descendant_of($repo, $commit, $ancestor);

Return true if C<$commit> is a descendant of C<$ancestor>.

=head2 Stash

=head2 git_stash_save

    Git::Libgit2::FFI::git_stash_save(\my $stash, $repo, $sig, $msg, $flags);

Save the current working directory state as a stash. Free with C<git_object_free>.

=head2 git_stash_apply

    Git::Libgit2::FFI::git_stash_apply($repo, $index, $opts);

Apply a stash by index.

=head2 git_stash_drop

    Git::Libgit2::FFI::git_stash_drop($repo, $index);

Drop a stash by index.

=head2 Reflog

=head2 git_reflog_read

    Git::Libgit2::FFI::git_reflog_read(\my $reflog, $repo, $name);

Read the reflog for a reference. Free with C<git_reflog_free>.

=head2 git_reflog_entrycount

    my $n = Git::Libgit2::FFI::git_reflog_entrycount($reflog);

Return the number of entries in the reflog.

=head2 git_reflog_entry_byindex

    my $entry = Git::Libgit2::FFI::git_reflog_entry_byindex($reflog, $idx);

Return the entry at the given index.

=head2 git_reflog_entry_id_new

    my $oid = Git::Libgit2::FFI::git_reflog_entry_id_new($entry);

Return the new OID of the entry.

=head2 git_reflog_entry_message

    my $msg = Git::Libgit2::FFI::git_reflog_entry_message($entry);

Return the message of the entry.

=head2 git_reflog_free

    Git::Libgit2::FFI::git_reflog_free($reflog);

Free the reflog handle.

=head2 Rebase

=head2 git_rebase_init

    Git::Libgit2::FFI::git_rebase_init(\my $rebase, $repo, $onto, $branch, $upstream, $opts);

Start a rebase operation. Free with C<git_rebase_free>.

=head2 git_rebase_open

    Git::Libgit2::FFI::git_rebase_open(\my $rebase, $repo, $state_dir);

Open an in-progress rebase. Free with C<git_rebase_free>.

=head2 git_rebase_next

    Git::Libgit2::FFI::git_rebase_next(\my $operation, $rebase);

Get the next operation in the rebase.

=head2 git_rebase_commit

    Git::Libgit2::FFI::git_rebase_commit($oid_ptr, $rebase, $author, $committer, $encoding, $message);

Commit the current rebase operation.

=head2 git_rebase_abort

    Git::Libgit2::FFI::git_rebase_abort($rebase);

Abort the rebase and reset to the original state.

=head2 git_rebase_finish

    Git::Libgit2::FFI::git_rebase_finish($rebase, $signer);

Finish a completed rebase.

=head2 git_rebase_free

    Git::Libgit2::FFI::git_rebase_free($rebase);

Free the rebase handle.

=head2 git_rebase_operation_entrycount

    my $n = Git::Libgit2::FFI::git_rebase_operation_entrycount($rebase);

Return the number of operations in the rebase.

=head2 git_rebase_operation_current

    my $n = Git::Libgit2::FFI::git_rebase_operation_current($rebase);

Return the current operation index (or C<GIT_REBASE_NO_OPERATION>).

=head2 git_rebase_operation_byindex

    my $op = Git::Libgit2::FFI::git_rebase_operation_byindex($rebase, $idx);

Return the operation at the given index.

=head2 git_rebase_options_init

    Git::Libgit2::FFI::git_rebase_options_init($opts_ptr, $version);

Initialize rebase options struct.

=head2 git_rebase_orig_head_name

    my $name = Git::Libgit2::FFI::git_rebase_orig_head_name($rebase);

Return the original HEAD name.

=head2 git_rebase_orig_head_id

    my $oid = Git::Libgit2::FFI::git_rebase_orig_head_id($rebase);

Return the original HEAD OID.

=head2 git_rebase_onto_name

    my $name = Git::Libgit2::FFI::git_rebase_onto_name($rebase);

Return the onto reference name.

=head2 git_rebase_onto_id

    my $oid = Git::Libgit2::FFI::git_rebase_onto_id($rebase);

Return the onto OID.

=head2 Cherry-pick

=head2 git_cherrypick

    Git::Libgit2::FFI::git_cherrypick($repo, $commit, $opts);

Prepare to cherry-pick a commit.

=head2 git_cherrypick_commit

    Git::Libgit2::FFI::git_cherrypick_commit(\my $oid, $repo, $cherrypick, $our_commit, $parent_count, $opts);

Create the actual cherry-pick commit.

=head2 git_cherrypick_options_init

    Git::Libgit2::FFI::git_cherrypick_options_init($opts_ptr, $version);

Initialize cherry-pick options struct.

=head2 Revert

=head2 git_revert

    Git::Libgit2::FFI::git_revert($repo, $commit, $opts);

Prepare to revert a commit.

=head2 git_revert_commit

    Git::Libgit2::FFI::git_revert_commit(\my $oid, $repo, $revert, $our_commit, $parent_count, $opts);

Create the actual revert commit.

=head2 git_revert_options_init

    Git::Libgit2::FFI::git_revert_options_init($opts_ptr, $version);

Initialize revert options struct.

=head2 ODB

=head2 git_odb_new

    Git::Libgit2::FFI::git_odb_new(\my $odb, $repo);

Create a new ODB wrapper. Free with C<git_odb_free>.

=head2 git_odb_exists

    my $exists = Git::Libgit2::FFI::git_odb_exists($odb, $oid_ptr);

Check if an object exists in the ODB.

=head2 git_odb_free

    Git::Libgit2::FFI::git_odb_free($odb);

Free the ODB handle.

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

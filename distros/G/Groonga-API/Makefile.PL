use strict;
use warnings;
use FindBin;
use ExtUtils::MakeMaker;

my $win32 = ($^O eq 'MSWin32');

# use Devel::CheckLib for sure?

my ($groonga_h, $inc, $libs) = check_env() or do {
  warn "groonga.h is not found; install groonga and/or set GROONGA_INC/GROONGA_LIBS environmental variables if necessary\n";
  exit(0);  # N/A
};

my @export_ok;
extract_constants($groonga_h);
extract_apis($groonga_h);
extract_bulk($groonga_h);
write_export(\@export_ok);

my %params = (
  NAME          => 'Groonga::API',
  AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
  VERSION_FROM  => 'lib/Groonga/API.pm',
  ABSTRACT_FROM => 'lib/Groonga/API.pm',
  LICENSE       => 'perl',
  OBJECT        => '$(O_FILES)',
  PREREQ_PM     => {
    'Exporter'            => 0,
    'JSON::XS'            => 0,
    'Path::Extended'      => 0,
    'Test::Differences'   => 0,
    'Test::More'          => '0.88',
    'Test::UseAllModules' => '0.10',
    'version'             => '0.77',
  },
  META_MERGE => {
    resources => {
      repository => 'https://github.com/charsbar/groonga-api',
    },
  },
  test => {TESTS => 't/*.t t/*/*.t'},
  clean => {FILES => '*.inc *.old *.log'},
);

$params{INC}  = $inc  if $inc;
$params{LIBS} = $libs if $libs;

my $eumm = eval $ExtUtils::MakeMaker::VERSION;
delete $params{LICENSE}          if $eumm < 6.31;
delete $params{META_MERGE}       if $eumm < 6.46;

WriteMakefile(%params);

#------------
# utilities
#------------

sub check_env {
  my ($groonga_h, $inc, $libs);

  my @incpath = qw(/usr/local/include /usr/include);
  if ($win32 && eval {require Win32}) {
    my $path = Win32::GetShortPathName('c:\Program Files\groonga\include');
    push @incpath, $path if $path;
  }
  if ($ENV{GROONGA_INC}) {
    $inc = $ENV{GROONGA_INC};
    $inc =~ s|^["']||;
    $inc =~ s|["']$||;
    $inc =~ s/^\-I//;
    $inc =~ s|\\|/|g;
    $inc =~ s|/$||g;
    unshift @incpath, $inc;
  }
  for (@incpath) {
    if (-e "$_/groonga/groonga.h") {
      $groonga_h = "$_/groonga/groonga.h";
      $inc = $_;
      last;
    }
  }
  return unless $groonga_h;

  (my $lib = $inc) =~ s|include$|lib|;
  $libs = $ENV{GROONGA_LIBS} || "-L$lib -l" . ($win32 ? "libgroonga.dll" : "groonga");
  $inc  = $ENV{GROONGA_INC}  || "-I$inc";

  return ($groonga_h, $inc, $libs);
}

sub extract_constants {
  my $groonga_h = shift;

  my $h = do {
    open my $fh, '<', $groonga_h or die "Can't open groonga.h: $!";
    local $/;
    <$fh>;
  };

  my @typedefs = $h =~ /typedef\s+enum\s*\{(.+?)\}\s*(\w+);/sg;
  my %seen;
  my %tags;
  my %ignore = map { $_ => 1 } qw/
    GRN_API GRN_INFO_CONFIGURE_OPTIONS GRN_INFO_CONFIG_PATH
    GRN_SNIP_MAPPING_HTML_ESCAPE GRN_NORMALIZER_AUTO
  /;

  while(my ($def, $tag) = splice @typedefs, 0, 2) {
    $tag =~ s/^grn_//;
    $def =~ s!/\*.+?\*/!!gs;
    $def =~ s!^#define .+!!mg;
    for (split /\s*,\s*/s, $def) {
      s/\s*=.+$//;
      s/^\s+//s;
      s/\s+$//s;
      next unless /^[A-Z0-9_]+$/;
      next if $ignore{$_};
      die "seen $_" if $seen{$_}++;
      push @{$tags{uc $tag} ||= []}, $_;
    }
  }

  my @defines_to_ignore = $h =~ /^#define\s+(GRN_[A-Z0-9_]+)\(/mg;
  for (@defines_to_ignore) {
    $ignore{$_} = 1;
  }

  my @defines_alias = $h =~ /^#define\s+(GRN_[A-Z0-9_]+\s+GRN_[A-Z0-9_]+)/mg;
  for (@defines_alias) {
    my ($def, $alias) = split /\s/;
    $ignore{$def} = 1 if $ignore{$alias};
  }

  my @defines = $h =~ /^#define\s+(GRN_[A-Z0-9_]+)/mg;

  for (@defines) {
    next if $ignore{$_};
    die "seen $_" if $seen{$_}++;
    push @{$tags{$1} ||= []}, $_ if /^GRN_(ID|COMMAND_VERSION|QUERY_LOG|OBJ_FORMAT|OBJ|CURSOR|TABLE_GROUP|TABLE|COLUMN|QUERY|SNIP|LOG|STRING|STR|EXPR|CTX)_/;
  }

  $tags{BOOL} = [qw/GRN_TRUE GRN_FALSE/];
  $tags{OBJ_TYPES} = [qw/GRN_VOID GRN_BULK GRN_PTR GRN_UVECTOR GRN_PVECTOR GRN_VECTOR GRN_MSG GRN_QUERY GRN_ACCESSOR GRN_ACCESSOR_VIEW GRN_SNIP GRN_PATSNIP GRN_STRING GRN_CURSOR_TABLE_HASH_KEY GRN_CURSOR_TABLE_PAT_KEY GRN_CURSOR_TABLE_DAT_KEY GRN_CURSOR_TABLE_NO_KEY GRN_CURSOR_TABLE_VIEW GRN_CURSOR_COLUMN_INDEX GRN_CURSOR_COLUMN_GEO_INDEX GRN_TYPE GRN_PROC GRN_EXPR GRN_TABLE_HASH_KEY GRN_TABLE_PAT_KEY GRN_TABLE_DAT_KEY GRN_TABLE_NO_KEY GRN_TABLE_VIEW GRN_DB GRN_COLUMN_FIX_SIZE GRN_COLUMN_VAR_SIZE GRN_COLUMN_INDEX/];

  $tags{all} = [sort keys %seen];

  {
    open my $out, '>', "$FindBin::Bin/constants.inc" or die "Can't open constants.inc: $!";
    my $alias = join "\n", map {"    $_ = $_"} sort keys %seen;
    print $out <<"END";
IV
grn_constant()
  ALIAS:
$alias
  CODE:
    RETVAL = ix;
  OUTPUT:
    RETVAL

END
  }

  {
    open my $out, '>', "$FindBin::Bin/lib/Groonga/API/Constants.pm" or die "Can't open Constants.pm";
    my $export_ok = join " ", sort keys %seen;
    my $export_tags = join ",\n  ",
      map {"$_ => [qw/" . join(" ", sort @{$tags{$_} || []}) ."/]"}
      sort keys %tags;

    print $out <<"END";
package Groonga::API::Constants;
use strict;
use warnings;
use base 'Exporter';
use Groonga::API;
our \@EXPORT_OK = qw($export_ok);
our \%EXPORT_TAGS = (
  $export_tags
);
1;

__END__

=head1 NAME

Groonga::API::Constants

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki\@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
END
  }
} # end of extract_constants()

sub extract_apis {
  my $groonga_h = shift;

  my $h = do {
    open my $fh, '<', $groonga_h or die "Can't open groonga.h: $!";
    local $/;
    <$fh>;
  };
  my @apis = $h =~ /\nGRN_API ([^;]+;)/gs;
  printf "Found %d APIs\n", scalar @apis;

  my %types;
  my $supported = 0;

  my %todo = map {("grn_$_" => 1)} (
    # grn_user_data *
    qw/obj_user_data/,

    # grn_search_optarg *
    qw/obj_search/,

    # int *
    qw/column_index/,

    # TODO: vector
    qw/vector_size vector_add_element vector_get_element/,

    # grn_table_group_result *
    qw/table_group/,

    # TODO: db
    qw/db_touch/,

    # TODO: void **
    qw/obj_get_values/,

    # TODO: const char **
    qw/pat_scan/,

    # TODO: expr
    qw/expr_add_var expr_alloc expr_append_const expr_append_const_int expr_append_const_str expr_append_obj expr_append_op expr_close expr_compile expr_create expr_exec expr_get_var expr_get_var_by_offset/,

    # TODO: proc
    qw/proc_create proc_get_info/,
    qw/proc_get_hook_local_data proc_get_ctx_local_data proc_call_next/,
    qw/ctx_set_finalizer proc_create obj_set_finalizer/,

    # get_hook_entry
    qw/obj_add_hook obj_get_nhooks obj_get_hook obj_delete_hook/,

    # TODO: callbacks
    qw/array_push array_pull/,
    qw/ctx_recv_handler_set/,

    # TODO: callbacks in struct
    qw/logger_set query_logger_set/,

    # TODO: snip (likely to be changed in groonga 3.0?)
    qw/snip_open snip_close snip_add_cond snip_exec snip_get_result expr_snip expr_snip_add_conditions snip_get_normalizer snip_set_normalizer/,

    # TODO: util?
    qw/charlen time_now/,

    # TODO: for mroonga
    qw/obj_delete_by_id obj_path_by_id/,

    # TODO: output (probably no need to provide)
    qw/output_envelope/,
    qw/ctx_output_array_close ctx_output_array_open ctx_output_bool ctx_output_cstr ctx_output_float ctx_output_int32 ctx_output_int64 ctx_output_map_close ctx_output_map_open ctx_output_str/,
    qw/output_obj ctx_output_obj/,

    # obsolete
    qw/str_close str_open text_otoj/,

    qw/query_logger_info_set/,

    # removed or changed (1.x.x)
    qw/query_rest query_scan query_snip/,
  ); # end of %todo

  my %inout = (
    grn_table_add => {'int *added' => 'OUT int added_out'},
    grn_table_get_key => {'void *keybuf' => 'void *keybuf_pv'},
    grn_table_cursor_get_key => {'void **key' => 'OUT void *key_out_length_RETVAL'},
    grn_table_cursor_get_value => {'void **value' => 'OUT void *value_out_length_RETVAL'},
    grn_ctx_recv => {
      'char **str' => 'OUT char *str_out',
      'unsigned int *str_len', 'OUT unsigned int str_len_out',
      'int *flags', 'OUT int flags_out',
    },
    grn_hash_add => {
      'int *added' => 'OUT int added_out',
      'void **value' => 'OUT void *value_out',
    },
    grn_hash_get => {'void **value' => 'OUT void *value_out'},
    grn_hash_get_key => {'void *keybuf' => 'void *keybuf_pv'},
    grn_hash_get_value => {'void *valuebuf' => 'void *valuebuf_pv'},
    grn_hash_cursor_get_key => {'void **key' => 'OUT void *key_out_length_RETVAL'},
    grn_hash_cursor_get_value => {'void **value' => 'OUT void *value_out_length_RETVAL'},
    grn_hash_cursor_get_key_value => {
      'void **key' => 'OUT void *key_out',
      'unsigned int *key_size' => 'OUT unsigned int key_size_out',
      'void **value' => 'OUT void *value_out_length_RETVAL',
    },
    grn_array_add => {'void **value' => 'OUT void *value_out'},
    grn_array_get_value => {'void *valuebuf' => 'void *valuebuf_pv'},
    grn_array_cursor_get_value => {'void **value' => 'OUT void *value_out_length_RETVAL'},
    grn_dat_add => {
      'int *added' => 'OUT int added_out',
      'void **value' => 'NULL',
    },
    grn_dat_get => {'void **value' => 'OUT void *value_out'},
    grn_dat_get_key => {'void *keybuf' => 'void *keybuf_pv'},
    grn_dat_cursor_get_key => {'const void **key' => 'OUT const void *key_out_length_RETVAL'},
    grn_pat_add => {
      'int *added' => 'OUT int added_out',
      'void **value' => 'OUT void *value_out',
    },
    grn_pat_get => {'void **value' => 'OUT void *value_out'},
    grn_pat_get_key => {'void *keybuf' => 'void *keybuf_pv'},
    grn_pat_get_value => {'void *valuebuf' => 'void *valuebuf_pv'},
    grn_pat_cursor_get_key => {'void **key' => 'OUT void *key_out_length_RETVAL'},
    grn_pat_cursor_get_value => {'void **value' => 'OUT void *value_out_length_RETVAL'},
    grn_pat_cursor_get_key_value => {
      'void **key' => 'OUT void *key_out',
      'unsigned int *key_size' => 'OUT unsigned int key_size_out',
      'void **value' => 'OUT void *value_out_length_RETVAL',
    },
    grn_table_sort_key_from_str => {'unsigned int *nkeys' => 'OUT unsigned int nkeys'},
    grn_index_cursor_next => {'grn_id *tid' => 'IN_OUT grn_id tid'},
    grn_string_get_original => {
      'const char **original' => 'OUT const char *original_out_length_length_in_bytes_out',
      'unsigned int *length_in_bytes' => 'OUT unsigned int length_in_bytes_out',
    },
    grn_string_get_normalized => {
      'const char **normalized' => 'OUT const char *normalized_out_length_length_in_bytes_out',
      'unsigned int *length_in_bytes' => 'OUT unsigned int length_in_bytes_out',
      'unsigned int *n_characters' => 'OUT unsigned int n_characters_out',
    },
    grn_table_get_subrecs => {
      'grn_id *subrecbuf' => 'OUT grn_id subrecbuf',
      'int *scorebuf' => 'OUT int scorebuf',
    },
  );

  {
    open my $out, '>', "$FindBin::Bin/api.inc" or die "Can't open api.inc: $!";
    for (@apis) {
      s/\s\s+/ /gs;
      s/\(void\)/()/g;
      s/\s+[A-Z][A-Z_]+\([^)]+\);/;/;
      my ($type, $decl) = split / /, $_, 2;
      if ($decl =~ /^grn_/) {
      } elsif ($decl =~ s/^(.+?)(_?grn_)/$2/) {
        $type .= " $1";
      }
      $decl =~ s/\s+[A-Z][A-Z_]+\([0-9]+\);$/;/;
      my ($name) = $decl =~ /^([^(]+)/;
      (my $export_name = $name) =~ s/^grn_//;
      push @export_ok, $export_name;
      if ($inout{$name}) {
        if (ref $inout{$name}) {
          for (keys %{$inout{$name}}) {
            $decl =~ s/\Q$_\E/$inout{$name}{$_}/;
          }
        }
        else {
          $decl =~ s/\Q$inout{$name}\E/IN_OUT $inout{$name}_inout/;
        }
      }

      if ($todo{$name}) {
        print $out "# $type\n# $decl\n\n";
      } else {
        $types{$type} = 1;
        print $out "$type\n$decl\n\n";
        $supported++;
      }
    }
  }
  printf "Supported %d APIs\n", $supported;

  my %map = (
    'grn_ctx *' => 'T_GRN_CTX',
    'grn_obj *' => 'T_GRN_OBJ',
  );
  my %grn_extra = (
    'grn_db_create_optarg *' => 'T_GRN_IGNORE',
    'grn_obj_flags' => 'T_U_SHORT',
    'grn_content_type' => 'T_ENUM',
    'grn_operator' => 'T_ENUM',
    'grn_array *' => 'T_GRN_OBJ',
    'grn_hash *' => 'T_GRN_OBJ',
    'const grn_logger_info *' => 'T_GRN_LOGGER_INFO',
    grn_id => 'T_U_INT',
    grn_bool => 'T_U_CHAR',
    grn_expr_flags => 'T_U_INT',
    'grn_table_delete_optarg *' => 'T_GRN_IGNORE',
    grn_info_type => 'T_ENUM',
    'grn_table_sort_key *' => 'T_GRN_TABLE_SORT_KEY',
    'grn_ctx_info *' => 'T_GRN_CTX_INFO',
  );
  my %extra = (
    'long long int' => 'T_IV',
    'long long unsigned int' => 'T_UV',
    'const void *' => 'T_PV_OR_UNDEF',
    'const char *' => 'T_PV_OR_UNDEF',
    'const unsigned char *' => 'T_PV_OR_UNDEF',
    'char *' => 'T_PV_OR_UNDEF',
    'void *' => 'T_OPAQUE_',
    'const short *' => 'T_OPAQUE_',
    'short *' => 'T_OPAQUE_',
  );

  {
    open my $out, '>', "$FindBin::Bin/typemap" or die "Can't open typemap";
    print $out "TYPEMAP\n";
    for (sort keys %types) {
      if (/^grn_/) {
        if ($map{$_}) {
          print $out $_, "\t", $map{$_}, "\n";
        } elsif (/\*$/) {
          print $out $_, "\t", "T_GRN_OBJ\n";
        } else {
          print $out $_, "\t", "T_ENUM\n";
        }
      }
    }
    for (sort keys %grn_extra) {
      print $out $_, "\t", $grn_extra{$_}, "\n";
    }
    for (sort keys %extra) {
      print $out $_, "\t", $extra{$_}, "\n";
    }
    print $out <<'TYPEMAP';

INPUT
T_GRN_CTX
  if (!SvOK($arg)) {
    Newx($var, 1, grn_ctx);
    sv_setref_pv($arg, \"Groonga::API::ctx\", (void*)$var);
  } else if (sv_derived_from($arg, \"${(my $t=$type)=~s/^grn_/Groonga::API::/;$t=~s/\s*\*+$//;\$t}\")){
    IV tmp = SvIV((SV*)SvRV($arg));
    $var = INT2PTR($type, tmp);
  }
  else
    croak(\"$var is not of type ${(my $t=$type)=~s/^grn_/Groonga::API::/;$t=~s/\s*\*+$//;\$t}\")

T_GRN_OBJ
  if (!SvOK($arg)) {
    $var = NULL;
  } else if (sv_derived_from($arg, \"${(my $t=$type)=~s/^grn_/Groonga::API::/;$t=~s/\s*\*+$//;\$t}\")){
    IV tmp = SvIV((SV*)SvRV($arg));
    $var = INT2PTR($type, tmp);
  } else if (sv_derived_from($arg, \"Groonga::API::obj\")){
    IV tmp = SvIV((SV*)SvRV($arg));
    $var = INT2PTR($type, tmp);
  }
  else
    croak(\"$var is not of type ${(my $t=$type)=~s/^grn_/Groonga::API::/;$t=~s/\s*\*+$//;\$t}\")

T_GRN_TABLE_SORT_KEY
  if (!SvOK($arg)) {
    $var = NULL;
  } else if (sv_derived_from($arg, \"${(my $t=$type)=~s/^grn_/Groonga::API::/;$t=~s/\s*\*+$//;\$t}\")){
    IV tmp = SvIV((SV*)SvRV($arg));
    $var = INT2PTR($type, tmp);
  }
  else
    croak(\"$var is not of type ${(my $t=$type)=~s/^grn_/Groonga::API::/;$t=~s/\s*\*+$//;\$t}\")

T_GRN_IGNORE
  $var = NULL;

T_PV_OR_UNDEF
  if (!SvOK($arg)) {
    $var = NULL;
  } else {
    $var = ($type)SvPV_nolen($arg);
  }

T_OPAQUE_
  $var = ${$var =~ /_pv/ ? \qq{($type)} : \qq{*($type *)}}SvPV_nolen($arg)

T_GRN_LOGGER_INFO
  STMT_START {
    SV* const xsub_tmp_sv = $arg;
    SvGETMAGIC(xsub_tmp_sv);
    if (SvROK(xsub_tmp_sv)) {
      HV* const xsub_tmp_hv = (HV *)SvRV(xsub_tmp_sv);
      static grn_logger_info logger_info;

      if (hv_exists(xsub_tmp_hv, \"max_level\", 9)) {
        SV **value;
        if ((value = hv_fetch(xsub_tmp_hv, \"max_level\", 9, 0)) != NULL) {
          logger_info.max_level = SvIV(*value);
        }
      }
      if (hv_exists(xsub_tmp_hv, \"flags\", 5)) {
        SV **value;
        if ((value = hv_fetch(xsub_tmp_hv, \"flags\", 5, 0)) != NULL) {
          logger_info.flags = SvIV(*value);
        }
      }
      /* TODO: callback support? */
      logger_info.func = NULL;
      logger_info.func_arg = NULL;

      $var = &logger_info;
    }
    else {
      croak(\"%s: %s is not a hash reference\", 
        ${$ALIAS?\q[GvNAME(CvGV(cv))]:\qq[\"$pname\"]},
        \"$var\");
    }
  } STMT_END

T_GRN_CTX_INFO
  if (!SvOK($arg)) {
    Newx($var, 1, grn_ctx_info);
    sv_setref_pv($arg, \"Groonga::API::ctx_info\", (void*)$var);
  } else if (sv_derived_from($arg, \"Groonga::API::ctx_info\")){
    IV tmp = SvIV((SV*)SvRV($arg));
    $var = INT2PTR($type, tmp);
  }
  else
    croak(\"$var is not of type Groonga::API::ctx_info\")

OUTPUT
T_GRN_CTX
  sv_setref_pv($arg, \"Groonga::API::ctx\", (void*)$var);

T_GRN_OBJ
  sv_setref_pv($arg, \"${(my $t=$type)=~s/^grn_/Groonga::API::/;$t=~s/\s*\*+$//;\$t}\", (void*)$var);

T_GRN_TABLE_SORT_KEY
  sv_setref_pv($arg, \"${(my $t=$type)=~s/^grn_/Groonga::API::/;$t=~s/\s*\*+$//;\$t}\", (void*)$var);

T_PV_OR_UNDEF
  if ($var != NULL) {
    sv_setpv((SV*)$arg, $var);
  } else {
    $arg = &PL_sv_undef;
  }

T_OPAQUE_
  sv_setpvn($arg, (char *)${ $var =~ /_out(_length_.+)?$/ ? \$var : \qq{\&$var} }, ${ $var =~ /_length_(\w+)/ ? \qq{$1} : \qq{sizeof($var)}});

TYPEMAP
  }
} # end of extract_apis

sub extract_bulk {
  my $groonga_h = shift;

  my $h = do {
    open my $fh, '<', $groonga_h or die "Can't open groonga.h: $!";
    local $/;
    <$fh>;
  };

  open my $out, '>', "$FindBin::Bin/bulk.inc" or die "Can't open bulk.inc: $!";

  my %value_type = (
    BOOL => 'unsigned char',
    INT8 => 'char',
    UINT8 => 'unsigned char',
    INT16 => 'short',
    UINT16 => 'unsigned short',
    INT32 => 'int',
    UINT32 => 'unsigned int',
    INT64 => 'long long int',
    UINT64 => 'long long unsigned int',
    FLOAT => 'double',
    TIME => 'long long int',
    RECORD => 'grn_id',
    PTR => 'grn_obj *',
    TEXT => 'char *',
    SHORT_TEXT => '',
    LONG_TEXT => '',
  );

  {
    my @init = $h =~ /#define GRN_([A-Z0-9_]+)_INIT\(/g;
    for (@init) {
      next unless exists $value_type{$_};
      push @export_ok, $_."_INIT";
      if ($_ eq 'PTR') {
        print $out <<"END";
SV *
${_}_INIT(grn_obj *obj, unsigned int flags, grn_id domain)
  CODE:
    GRN_${_}_INIT(obj, flags, domain);
    XSRETURN_YES;

END
      } else {
        print $out <<"END";
SV *
${_}_INIT(grn_obj *obj, unsigned int flags)
  CODE:
    GRN_${_}_INIT(obj, flags);
    XSRETURN_YES;

END
      }
    }
  }

  {
    my @set = $h =~ /#define GRN_([A-Z0-9_]+)_SET\(/g;
    for (@set) {
      next unless $value_type{$_};
      my $s = $_ eq "TEXT" ? "S" : "";
      push @export_ok, $_."_SET$s";
      print $out <<"END";
SV *
${_}_SET$s(grn_ctx *ctx, grn_obj *obj, $value_type{$_} value)
  CODE:
    GRN_${_}_SET$s(ctx, obj, value);
    XSRETURN_YES;

END
    }
  }

  {
    my @set_at = $h =~ /#define GRN_([A-Z0-9_]+)_SET_AT\(/g;
    for (@set_at) {
      next unless $value_type{$_};
      push @export_ok, $_."_SET_AT";
      print $out <<"END";
SV *
${_}_SET_AT(grn_ctx *ctx, grn_obj *obj, unsigned int offset, $value_type{$_} value)
  CODE:
    GRN_${_}_SET_AT(ctx, obj, offset, value);
    XSRETURN_YES;

END
    }
  }

  {
    my @value = $h =~ /#define GRN_([A-Z0-9_]+)_VALUE\(/g;
    for (@value) {
      next unless $value_type{$_};
      push @export_ok, $_."_VALUE";
      print $out <<"END";
$value_type{$_}
${_}_VALUE(grn_obj *obj)
  CODE:
    RETVAL = GRN_${_}_VALUE(obj);
  OUTPUT:
    RETVAL

END
    }
  }

  {
    my @value_at = $h =~ /#define GRN_([A-Z0-9_]+)_VALUE_AT\(/g;
    for (@value_at) {
      next unless $value_type{$_};
      push @export_ok, $_."_VALUE_AT";
      print $out <<"END";
$value_type{$_}
${_}_VALUE_AT(grn_obj *obj, unsigned int offset)
  CODE:
    RETVAL = GRN_${_}_VALUE_AT(obj, offset);
  OUTPUT:
    RETVAL

END
    }
  }
} # end of extract_bulk

sub write_export {
  my $export_ok = shift;
  push @$export_ok, qw/
    get_major_version
    EXPR_CREATE_FOR_QUERY
    CHAR_TYPE CHAR_IS_BLANK 
    TEXT_LEN
  /;

  my %tags = (all => \@$export_ok);

  {
    open my $out, '>', "$FindBin::Bin/lib/Groonga/API/Exports.pm" or die "Can't open Exports.pm";
    $export_ok = join " ", sort @$export_ok;
    my $export_tags = join ",\n  ",
      map {"$_ => [qw/" . join(" ", sort @{$tags{$_} || []}) ."/]"}
      sort keys %tags;

    print $out <<"END";
package Groonga::API::Exports;
use strict;
use warnings;
our \@EXPORT_OK = qw($export_ok);
our \%EXPORT_TAGS = (
  $export_tags
);
1;

__END__

=head1 NAME

Groonga::API::Exports

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki\@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
END
  }
} # end of write_export

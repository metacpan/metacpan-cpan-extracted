package Apache::WebDAO;
use HTML::WebDAO;
use HTML::WebDAO::CVapache2;
use HTML::WebDAO::SessionID;
use HTML::WebDAO::Sessiondb;
use HTML::WebDAO::Lex;
use HTML::WebDAO::Store::MLDBM;
use strict;
use warnings;
use Apache2::RequestRec();
use Apache2::RequestIO ();
use Apache2::URI       ();
use Data::Dumper;
use CGI;
use Cwd;
use Apache2::Const -compile => qw(OK DECLINED);
my $lexer;

sub get_config {
    Apache2::Module::get_config( 'Apache::Directives2', @_ );
}

sub handler {
    my $r = shift;
    return Apache2::Const::DECLINED if -e $r->filename and !-d $r->filename;

    #get configs
    my $s       = $r->server;
    my $dir_cfg = get_config( $s, $r->per_dir_config );
    my $srv_cfg = get_config($s);
    my %cfg;
    foreach my $key ( grep { /^wd/ } keys %{$srv_cfg}, keys %{$dir_cfg} ) {
        my $val =
            exists $srv_cfg->{$key} ? $srv_cfg->{$key}
          : exists $dir_cfg->{$key} ? $dir_cfg->{$key}
          : next;
        $cfg{$key} = $val;
    }
    my $store_obj =
      ( $cfg{wdStore} || 'HTML::WebDAO::Store::Abstract' )->new( %{ $cfg{wdStorePar} || {} } );
    my $sess_class = $cfg{wdSession} || 'HTML::WebDAO::Session';
    my $sess = $sess_class->new(
        {
            %{ $cfg{wdSessionPar} || {} },
            store => $store_obj,
            cv    => new HTML::WebDAO::CVapache2:: $r,

        }
    );
    $sess->set_header( -type => 'text/html; charset=utf-8' );

#    $sess->Cgi_env->{path_info_elments} = [ grep { $_ && defined $_  && !/sess/} split( /\//, $r->uri ) ];
    my $dir = getcwd;
    chdir( $r->document_root );
#    my $index_file = $r->dir_config->get('wd_indexfile');
    my $index_file = $cfg{wdIndexFile};#||$r->dir_config->get('wd_indexfile')||'index.xhtml';

    my $filename = $index_file;
    my $content  = qq!<wD><include file="$filename"/></wD>!;
    $lexer = HTML::WebDAO::Lex->new( content => $content ) unless $lexer;
    my $eng = HTML::WebDAO::Engine->new(
        "index", $content,
        lexer    => $lexer,
        session  => $sess
    );
    $sess->ExecEngine($eng);
    chdir($dir);

    #    return Apache2::Const::DECLINED unless  -d $r->filename;
    #    $r->content_type('text/plain');
    #    my $cgi = CGI::new;

=pod
    my $s       = $r->server;
    my $dir_cfg = get_config( $s, $r->per_dir_config );
    my $srv_cfg = get_config($s);
print "<pre>" . Dumper(
        {
            '%cfg' => \%cfg,
            '$r'=>ref($r),
            #            '$r->uri'        => $r->uri,
            '$s->is_virtual' => $s->is_virtual,
            '$r->filename'   => $r->filename,
            '$r->parsed_uri' => $r->parsed_uri,
            '$dir_cfg'       => $dir_cfg,
            '$srv_cfg'       => $srv_cfg,

            #            '$cgi->param' => [ $cgi->param ],
            '$r->content_type' => $r->content_type,

            #            '$cgi->path_info()'=>$cgi->path_info,
            '$r->dir_config()'  => $r->dir_config(),
            '$r->document_root' => $r->document_root
        }
    );

    #    print '<pre>'.Dumper($r->dir_config('PlaylistImage')).'</pre>';
    #    print '<pre>'.Dumper($r->dir_config()).'</pre>';
    #        print "<pre>".Dumper(\%ENV)."</pre>";
=cut

    return Apache2::Const::OK;
}
1;


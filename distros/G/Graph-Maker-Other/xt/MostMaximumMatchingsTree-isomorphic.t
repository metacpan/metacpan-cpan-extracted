#!/usr/bin/perl -w

# Copyright 2017, 2019, 2020, 2021 Kevin Ryde
#
# This file is part of Graph-Maker-Other.
#
# This file is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# This file is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Maker-Other.  See the file COPYING.  If not, see
# <http://www.gnu.org/licenses/>.

use strict;
use 5.004;
use FindBin;
use File::Slurp;
use Graph;
use Graph::Reader::Graph6;
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use MyGraphs;

# uncomment this to run the ### lines
# use Smart::Comments;

plan tests => 881;

require Graph::Maker::MostMaximumMatchingsTree;


#------------------------------------------------------------------------------
# N=6, 6.5

{
  my $graph = Graph::Maker->new('most_maximum_matchings_tree',
                                undirected => 1,
                                N => 6);
  ok (scalar($graph->vertices), 6);

  my $other = Graph::Maker->new('most_maximum_matchings_tree',
                                undirected => 1,
                                N => 6.5);
  ok (scalar($other->vertices), 6);

  ok (! MyGraphs::Graph_is_isomorphic($graph, $other), 1,
     "N=6 different N=6.5");
}

#------------------------------------------------------------------------------
# N=34, 34.5

{
  my $graph = Graph::Maker->new('most_maximum_matchings_tree',
                                undirected => 1,
                                N => 34);
  ok (scalar($graph->vertices), 34);

  my $other = Graph::Maker->new('most_maximum_matchings_tree',
                                undirected => 1,
                                N => 34.5);
  ok (scalar($other->vertices), 34);

  ok (! MyGraphs::Graph_is_isomorphic($graph, $other), 1,
     "N=34 different N=34.5");
}

#------------------------------------------------------------------------------
# POD HOG Shown

{
  my %shown;
  {
    my $content = File::Slurp::read_file
      (File::Spec->catfile($FindBin::Bin,
                           File::Spec->updir,
                           'lib','Graph','Maker',
                           'MostMaximumMatchingsTree.pm'));
    $content =~ /=head1 HOUSE OF GRAPHS.*?=head1/s or die;
    $content = $&;
    my $count = 0;
    while ($content =~ /^ +(?<ids>(\d+, )*\d+) +N=(?<Nlo>[0-9.]+)( to N=(?<Nhi>[0-9]+))?/mg) {
      $count++;
      my $ids = $+{'ids'};
      my $Nlo = $+{'Nlo'};
      my $Nhi = $+{'Nhi'} // $Nlo;
      my @ids = split /, /, $ids;
      ### match: "$ids  $Nlo $Nhi"
      for (my $N = $Nlo; $N <= $Nhi; $N++) {
        @ids or die;
        my $id = shift @ids;
        my $key = "N=$N";
        ok (! exists $shown{$key}, 1);
        $shown{"N=$N"} = $id;
      }
      ok (scalar(@ids), 0);
    }
    ok ($count, 19, 'HOG ID number of lines');
  }
  ok (scalar(keys %shown), 34 + 2 + 1);
  ### %shown

  my $extras = 0;
  my $compared = 0;
  my @notseen;
  my %seen;
  foreach my $N (1 .. 40, 34.5) {
    my $graph = Graph::Maker->new('most_maximum_matchings_tree',
                                  undirected => 1,
                                  N => $N);
    my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
    $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
    # next if $seen{$g6_str}++;
    my $key = "N=$N";
    if (my $id = $shown{$key}) {
      MyGraphs::hog_compare($id, $g6_str);
      $compared++;
    } else {
      push @notseen, $key;
      if (MyGraphs::hog_grep($g6_str)) {
        my $name = $graph->get_graph_attribute('name');
        MyTestHelpers::diag ("HOG $key not shown in POD");
        MyTestHelpers::diag ($name);
        MyTestHelpers::diag ($g6_str);
        # MyGraphs::Graph_view($graph);
        $extras++;
      }
    }
  }
  ok ($extras, 0);
  MyTestHelpers::diag ("POD HOG $compared compares, notseen: ",
                       join(' ',@notseen));
}

#------------------------------------------------------------------------------

{
  # a past brute force search 
  my $want_sparse6s = <<'HERE';
:Ccf
:DaGb
:EaXbN
:EaGaN
:FaXbK
:GaXeLv
:H`EKWTjV
:I`ESgTlYF
:J`ESgTlYCN
:K`EShOl]{G^
:L`EShOl]|wO
:M`ESgTlYE\Y`
:N`ESxpbBE\Ypb
:O`ESxrbEE\ZvfN
:P_`aa_dee_hii_lmm
HERE

  $want_sparse6s =~ s/\n$//;
  my @want_sparse6s = split /\n/, $want_sparse6s;
  foreach my $i (0 .. $#want_sparse6s) {
    my $N = ($i <= 1 ? $i+4
             : $i == 2 ? 6.5       # T other
             : $i == 3 ? 6         # star
             : $i+3);
    my $n = int($N);
    my $graph = Graph::Maker->new('most_maximum_matchings_tree',
                                  undirected => 1,
                                  N => $N);
    ok (scalar($graph->vertices), $n,
        "i=$i");
    
    my $want_sparse6 = $want_sparse6s[$i];
    my $reader = Graph::Reader::Graph6->new;
    open my $fh, '<', \$want_sparse6 or die;
    my $want_graph = $reader->read_graph($fh);
    ok (scalar($want_graph->vertices), $n,
        "i=$i");
    
    ok (MyGraphs::Graph_is_isomorphic($graph, $want_graph), 1,
        "i=$i N=$N sparse6 data");
  }
}


#------------------------------------------------------------------------------

# Sparse6 strings for the trees of N=0 vertices upwards.
#
{
  my $want_sparse6s = <<'HERE';
:?
:@
:An
:Bd
:Cdn
:DaGb
:EaGaN
:FaGnK
:GaXnKf
:Hc?KWp`AF
:I`ASxol]~
:J`EKySb^EN
:K`ACITj^EI~
:L`ACGtjUU[x
:M`ACySl]|LZv
:N`EKySb^ELZvb
:Oc?KWp`Y|{yt]CN
:P_`aa_dee_hii_lmm
:Q_``bcc`fggijjgmnn
:R__abbdeeb__jkkmnnk
:S___d?CcchCGgggkllnool
:T___bcceffcijjlmmjpqq
:U_``bcc`fggijjgmnnpqqn
:Va?@`bcceffc``_lmmoppm__
:W_`aa_dee_hiiklliopp_stt
:X_``bcc`fggijjgmnnpqqntuu
:Y_`aacdda_hiiklli__qrrtuur
:Za?@`bcc`fgg`jkk_noo_rss_vww
:[___bcceffcijjlmmjpqqsttqwxx
:\_``bcc`fggijjgmnnpqqntuuwxxu
:]a?@`bcceffc``_lmmoppm__uvvxyyv
:^_`aa_deeghhekll_opprsspvww_z{{
:__``bcc`fggijjgmnnpqqntuuwxxu{||
:`_OWSIHDaogCeTIeRXki@?hSy\UlUhuZTix\mun
:a`??KEFCaOW{aP@drHcA^OgSi\M`UjtwDivZ_Vj|~
:b_OGCMHCbPw{QTJdrXsyVPhSidUjQkUZLmx[kv{EB
:c_OWKMHC_pxCaTJdqHs}^PhSh|UlUkUZLYx\mv{EAz
:d`??KEFCaPg{]H@_rHku^OgRWDQjTjuJDU@?mvjuBB`n^
:e_OWSIHDaohCeR?eRXk}`OesydQ@VkUJTmvWnVz{BDbp~
:f_OWKMHC_pxCaTJdqHs}^PhSh|UlUkUZLYx\mv{EAzbqXN
:g_OWSIHDaogCeTIeRXki`PgsydQb?_UZTix\mukEFBbqXKN
:h`??KEFCaPg{]HIdqwKy^N_si\M@UjtzLitVmvjsBBapOKmZL
:i_OGCMHCbPw{QTJdrXsyVPhSidUjQkUZLmx[kv{EBDbpwKu^N
:j_OWKMHC_pxCaTJdqHs}^PhSh|UlUkUZLYx\mv{EAzbqXKu^Nc
:k`??KEFCaPg{]H@_rHku^OgRWDQjTjuJDUv[mVj|}x?_XKmVNgsX^
:l_OWSIHDaohCeR?eRXk}`OesydQ@VkUJTmvWnVz{BDbpx[uZFhtYn
:m_OWKMHC_pxCaTJdqHs}^PhSh|UlUkUZLYx\mv{EAzbqXKu^NctY|^
:n_OWSIHDaohCeRJeRHKA`PgsydQbVkUJTmvW_OKEFBbqXKM^PgtY|]b
:o`??KEFCaPg{]HIdqwKy^N_si\M@UjtzLitVmvjsBBapOKmZLgsy[urZl
:p_OGCMHCbPw{QTJdrXsyVPhSidUjQkUZLmx[kv{EBDbpwKu^NhtYk}v\m
:q_OWKMHC_pxCaTJdqHs}^PhSh|UlUkUZLYx\mv{EAzbqXKu^NctY|]v\mt~
:r`??KEFCaPg{]HIdqxky\J_oY\QhUjtycAv[mVj|}xapw{mZLb_OL]rXmvz|f
:s_OWSIHDaohCeR?eRXk}`OesydQ@VkUJTmvWnVz}FDanx[uY@htYlevZiw[]N
:t_OWKMHC_pxCaTJdqHs}^PhSh|UlUkUZLYx\mv{EAzbqXKu^NctY|]v\mt{]VJ
:u_OWSIHDaohCeRJeRHKA`PgsydQbVkUJTmvW_OKEFBbqXKM^PgtY|]b\nv{]VJ^
:v`??KEFCaPg{]HIdqwKy^NgsiS}jUjOZLit?mvjuBB`nXKmU@gsyWErZlv{MEvfsy^
:w_OGCMHCbPw{QTJdrXsyVPhSidUjQkUZLmx[kv{EBDbpwKu^NhtYk}v\mw[]Mzhty~
:x_OWKMHC_pxCaTJdqHs}^PhSh|UlUkUZLYx\mv{EAzbqXKu^NctY|]v\mt{]VJhty{n
:y`??KEFCaPg{]HIdqxky\J_oY\QhUjtycAv[mVj|}xapw{mZLb_OL]rXmvz|fJfry|mvN
:z_OWSIHDaohCeR?eRXk}`OesydQlVjtJTmv?nVz}FDanx[uZPhsxlevZ?w[]NNhsw|~Fb
:{_OWKMHC_pxCaTJdqHs}^PhSh|UlUkUZLYx\mv{EAzbqXKu^NctY|]v\mt{]VJhty{nFfr
:|_OWSIHDaohCeRJeRHKA`PgsydQbVkUJTmvWnVz}FDanoGE^PgtY|]b\nv{]VJ^tz\nFfru
:}`??KEFCaPg{]HIdqwKy^NgsiS}jUjOZLit?mvjuBB`nXKmU@gsy\]rXhv{MCBfsy\m~^hy|}~
:~??~_OGCMHCbPw{QTJdrXsyVPhSidUjQkUZLmx[kv{EBDbpwKu^NhtYk}v\mw[]Mzhty|~Fbjz}^N
:~?@?_OWKMHC_pxCaTJdqHs}^PhSh|UlUkUZLYx\mv{EAzbqXKu^NctY|]v\mt{]VJhty{nFfrz}^NN
:~?@@__?@_WMC`GYF`wQIawmLbgyJ_WERdHQUdx]SehmZfXy]ewAagyMdhiYbiYiijIuligA?kjMrlZYukzeymjq|nZj
:~?@A_GEA_gQD`WIGaWeJbGqHbxAO_HMSdHYVdxQYexm\fhyZgYIa_IUehiahiYYkjYunkJAlkzQs_J]wmJizmza}nz~
:~?@B_GE@_wQC_W]GaGiJawaMbw}PchINdXYUeHeXdhq\fX}_gHubhIQehy]ciimjjYymizEqkjQtlZIwmZeznJqxn{B?
:~?@C_GEA_gQD`WIGaWeJbGqHbxAOchMRcGAVeHaYexmWfh}^gYIafyUehiahiYY?_IynjzEqki}tljYwmZeunJu|n{B?n^
:~?@D__?@_WMC`GYF`wQIawm@bg}NcXIQbxUUdgEXehi[fXuYgIE`_IQdhY]giIUjjIq?jzAokjMrkJYvlwAymzm|njyzo[JA
:~?@E_GA?_wQC`g]F`GiJawuMbgmPchISdXUQeHeXexq[eX}_gIIbgyAehy]hiiifjYymkJEpjjQtlZ]wmJUznJq}nz}{okNB
:~?@F_GE@_wQC_W]GaGiJawaMbw}PchINdXYUeHeXdhq\fX}_gHubhIQehy]ciimjjYymizEqkjQtlZIwmZeznJqxn{B?okNBoN
:~?@G_GEA_gQD`WcAAGaIawmLbgyJcXIQdHUTcgaGehmZfXy]eyEagiQdhYI?iYiijIulijApkZMslJE?_Jeymjq|nZj?o[FBpKR@
:~?@H_GEA_gQD`WIGaWeJbGqHbxAO_HMSdHYVdxQYexm\fhyZgYIa_IUehiahiYYkjYunkJAlkzQs_J]wmJizmza}nz~@okI~p[ZE
:~?@I_GE@_wQC_W]GaGiJawaMbw}PchINdXYUeHeXdhq\fX}_gHubhIQehy]ciimjjYymizEqkjQtlZIwmZeznJqxn{B?okNBoKZFp~
:~?@J_GEA_gQD`WIGaWeJbGqHbxAOchMRcGAVeHaYexmWfh}^gYIafyUehiahiYY?_IynjzEqki}tljYwmZeunJu|n{B?n[NCpKZFp{R
:~?@K_GEA_gQD`WcAAGaIawmLbgyJcXIQaHUUdhaXeXY[fXuGgIE`gyQcgY]giGAjjIqmjy}kkjMr_JYvlzeymj]|njy?o[JApKVDokbHq^
:~?@L_GA?_wQC`g]F`GiJawuMbgmPchISdXUQeHeXexq[eX}_gIIbgyAehy]hiiifjYymkJEpjjQtlZ]wmJUznJq}nz}{okNBp[ZEo{fIqn
:~?@M_GE@_wQC_W]GaGiJawaMbw}PchINdXYUeHeXdhq\fX}_gHubhIQehy]ciimjjYymizEqkjQtlZIwmZeznJqxn{B?okNBoKZFp{fIqk^
:~?@N_GEA_gQD`WcAAGaIawmLbgyJcXIQdHUTcgaGehmZfXy]eyEagiQdhYI?iYiijIulijApkZMslJEvmJaymzmw_GB?o[FBpKR@p{bGqknJqN
:~?@O_GEA_gQD`WIGaWeJbGqHbxAO_HMSdHYVdxQYexm\fhyZgYIa_IUehiahiYYkjYunkJAlkzQslj]vlJizmwA}nz~@okI~p[ZEqKfHpkrLr^
:~?@P_GE@_wQC_W]GaGiJawaMbw}PchINdXYUeHeXdhq\fX}_gHubhIQehy]ciimjjYymizEqkjQtlZIwmZeznJqxn{B?okNBoKZFp{fIqk^Lrkz
:~?@Q_GEA_gQD`WIGaWeJbGqHbxAOchMRcGAVeHaYexmWfh}^gYIafyUehiahiYYkjYunkJAl_GAtljYwmZeunJu|n{B?n[NCpKZFp{RIq{nLrkzJ
:~?@R_GEA_gQD`WcAAGaIawmLbgyJcXIQaHUUdhaXeXY[fXuGgIE`gyQcgY]giGAjjIqmjy}kkjMrlZYukzeymgA|njz?o[E}pKVD_KbHq[nKrKfNsLB
:~?@S_GA?_wQC`g]F`GiJawuMbgmPchISdXUQeHeXexq[eX}_gIIbgyAehy]hiiifjYymkJEpjjQtlZ]wmJUznJq}nz}{okNBp[ZEo{fIqkrLr[jOs\F
:~?@T_GE@_wQC_W]GaGiJawaMbw}PchINdXYUeHeXdhq\fX}_gHubhIQehy]ciimjjYymizEqkjQtlZIwmZeznJqxn{B?okNBoKZFp{fIqk^LrkzOs\FM
:~?@U_GEA_gQD`WcAAGaIawmLbgyJcXIQdHUTchaXeXm[fHeGaIEagiQdhYIgiYejjIqh_JApkZMslJEvmJaymzmwnj}~o[JAnwA?p{bGqknJqKzNr|FQsk~
:~?@V_GEA_gQD`WIGaWeJbGqHbxAO_HMSdHYVdxQYexm\fhyZgYIahIUdgiahiWAkjYunkJAlkzQslj]vlJizmzu}njn@okI?p[ZEqKfHpkrLr[~OsKvRtLR
:~?@W_GE@_wQC_W]GaGiJawaMbw}PchINdXYUeHeXdhq\fX}_gHubhIQehy]ciimjjYymizEqkjQtlZIwmZeznJqxn{B?okNBoKZFp{fIqk^LrkzOs\FMtLVT
:~?@X_GEA_gQD`WIGaWeJbGqHbxAOchMRcHYVdxeYeh]?fh}^gYIafyUehiahiYYkjYunkJAlkzQslj]vlGA?nJu|n{B?n[NCpKZFp{RIq{nLrkzJs\JQtLVTsn
:~?@Y_GEA_gQD`WcAAGaIawmLbgyJcXIQdHUTchaXeWa[fXu^gIA\gyQcaI]giIijiyamjy}?kjMrlZYukzeymjq|nZj?o[E?pKVDp{bGp[nKrGBNsLBQs|NOtl^V
:~?@Z_GA?_wQC`g]F`GiJawuMbgmPchISdXUQeHeXexq[eX}_gIIbgyAehy]hiiifjYymkJEpjjQtlZ]wmJUznJq}nz}{okNBp[ZEo{fIqkrLr[jOs\FRtLRPt|bW
:~?@[_GE@_wQC_W]GaGiJawaMbw}PchINdXYUeHeXdhq\fX}_gHubhIQehy]ciimjjYymizEqkjQtlZIwmZeznJqxn{B?okNBoKZFp{fIqk^LrkzOs\FMtLVTt|bWt^
:~?@\_GEA_gQD`WcAAGaIawmLbgyJcXIQdHUTchaXeXm[fHeGaIEagiQdhYIgiYejjIqh_JApkZMslJEvmJaymzmwnj}~o[JAnwA?p{bGqknJqKzNr|FQsk~TtlZWu\fU
:~?@]_GEA_gQD`WIGaWeJbGqHbxAOchMRcHYVdwAYexm\fhyZgYIahIUdgiahiYmkjIenkJA?kzQslj]vlJizmzu}njn@okJCp[VAqKfH_KrLr[~OsKvRtLRUt|^SulnZ
:~?@^_GE@_wQC_W]GaGiJawaMbw}PchINdXYUeHeXdhq\fX}_gHubhIQehy]ciimjjYymizEqkjQtlZIwmZeznJqxn{B?okNBoKZFp{fIqk^LrkzOs\FMtLVTt|bWt\n[vN
:~?@__GEA_gQD`WIGaWeJbGqHbxAOchMRcHYVdxeYeh]?fh}^gYIafyUehiahiYYkjYunkJAlkzQslj]vlGA?nJu|n{B?n[NCpKZFp{RIq{nLrkzJs\JQtLVTslbXu\n[vLf
:~?@`_GEA_gQD`WcAAGaIawmLbgyJcXIQdHUTchaXeWa[fXu^gIA\gyQcaI]giIijiyamjy}?kjMrlZYukzeymjq|nZj?o[E?pKVDp{bGp[nKrGBNsLBQs|NOtl^Vu\jYt|v]vn
:~?@a_GA?_wQC`g]F`GiJawuMbgmPchISdXUQeHeXexq[eX}_gIIbgyAehy]hiiifjYymkJEpjjQtlZ]wmJUznJq}nz}{okNBp[ZEo{fIqkrLr[jOs\FRtLRPt|bWulnZuLz^v~
:~?@b_GE@_wQC_W]GaGiJawaMbw}PchINdXYUeHeXdhq\fX}_gHubhIQehy]ciimjjYymizEqkjQtlZIwmZeznJqxn{B?okNBoKZFp{fIqk^LrkzOs\FMtLVTt|bWt\n[vLz^v|r
:~?@c_GEA_gQD`WcAAGaIawmLbgyJcXIQdHUTchaXeXm[fHeGaIEagiQdhYIgiYejjIqhjzAokjMrkGAvmJaymzmwnj}~o[JAn{VEpkbHq[Y?_KzNr|FQsk~TtlZWu\fUvLv\v}B_v^
:~?@d_GEA_gQD`WIGaWeJbGqHbxAOchMRcHYVdwAYexm\fhyZgYIahIUdgiahiYmkjIenkJA?kzQslj]vlJizmzu}njn@okJCp[VAqKfH_KrLr[~OsKvRtLRUt|^SulnZv\z]u}Fawn
:~?@e_GE@_wQC_W]GaGiJawaMbw}PchINdXYUeHeXdhq\fX}_gHubhIQehy]ciimjjYymizEqkjQtlZIwmZeznJqxn{B?okNBoKZFp{fIqk^LrkzOs\FMtLVTt|bWt\n[vLz^v|raw}N
:~?@f_GEA_gQD`WIGaWeJbGqHbxAOchMRcHYVdxeYeh]?fh}^gYIafyUehiahiYYkjYunkJAlkzQslj]vlJizmzu}njm?_KNCpKZFp{RIq{nLrkzJs\JQtLVTslbXu\n[vLf^wMBaw}N_
:~?@g_GEA_gQD`WcAAGaIawmLbgyJcXIQdHUTchaXeWa[fXu^gIA\gyQchi]fhIijiwamjy}pkjInlZYu_Jeymjq|nZj?o[FBpKR@p{bG_KnKrKzNr{rQs|M?tl^Vu\jYt|v]vmB`w\zcx]V
:~?@h_GA?_wQC`g]F`GiJawuMbgmPchISdXUQeHeXexq[eX}_gIIbgyAehy]hiiifjYymkJEpjjQtlZ]wmJUznJq}nz}{okNBp[ZEo{fIqkrLr[jOs\FRtLRPt|bWulnZuLz^v}Fawl~dxmZ
:~?@i_GE@_wQC_W]GaGiJawaMbw}PchINdXYUeHeXdhq\fX}_gHubhIQehy]ciimjjYymizEqkjQtlZIwmZeznJqxn{B?okNBoKZFp{fIqk^LrkzOs\FMtLVTt|bWt\n[vLz^v|raw}NdxmZb
:~?@j_GEA_gQD`WIGaWeJbGqOAO}NcXIQdHUTchaXeXm[fHe^gIAagyM_bw}giYejjIqhjzAokjMrkJYvlzeymj]?nj}~o[JAn{VEpkbHq[ZKr[vNsLBL_GBTtlZWu\fUvLv\v}B_v]NcxMZfx}R
:~?@k_GEA_gQD`WIGaWeJbGqHbxAOchMRcHYVdwAYexm\fhyZgYIahIUdgiahiYmkjIenkJA?kzQslj]vlJizmzu}njn@okJCp[VAqKfHq{rKq[~OsGBRtLRUt|^SulnZv\z]u}FawmRdx]Jgy]f
:~?@l_GE@_wQC_W]GaGiJawaMbw}PchINdXYUeHeXdhq\fX}_gHubhIQehy]ciimjjYymizEqkjQtlZIwmZeznJqxn{B?okNBoKZFp{fIqk^LrkzOs\FMtLVTt|bWt\n[vLz^v|raw}NdxmZby]ji
:~?@m_GEA_gQD`WIGaWeJbGqHbxAOchMRcHYVdxeYeh]\fhy_gYE]_IUehiahiYYkjYunkJAlkzQslj]vlJizmzu}njn@okJCp[VA_GBIq{nLrkzJs\JQtLVTslbXu\n[vLf^wMBaw}N_xm^fy]jix~
:~?@n_GEA_gQD`WcAAGaIawmLbgyJcXIQdHUTchaXeWa[fXu^gIA\gyQchi]fhIijiwamjy}pkjInlZYu_Jeymjq|nZj?o[FBpKR@p{bG_KnKrKzNr{rQs|NTtlZRu\jY_Lv]vmB`w\zcx]VfyMbdy}rk
:~?@o_GA?_wQC`g]F`GiJawuMbgmPchISdXUQeHeXexq[eX}_gIIbgyAehy]hiiifjYymkJEpjjQtlZ]wmJUznJq}nz}{okNBp[ZEo{fIqkrLr[jOs\FRtLRPt|bWulnZuLz^v}Fawl~dxmZgy]fezMvl
:~?@p_GE@_wQC_W]GaGiJawaMbw}PchINdXYUeHeXdhq\fX}_gHubhIQehy]ciimjjYymizEqkjQtlZIwmZeznJqxn{B?okNBoKZFp{fIqk^LrkzOs\FMtLVTt|bWt\n[vLz^v|raw}NdxmZby]jizMvlyn
:~?@q_GEA_gQD`WIGaWeJbGqOAO}NcXIQdHUTchaXeXm[fHe^gIAagyM_bw}giYejjIqhjzAokjMrkJYvlzeymj]?nj}~o[JAn{VEpkbHq[ZKr[vNsLBLs|RStl^VtGA?vLv\v}B_v]NcxMZfx}Riy}nlzmzj
:~?@r_GEA_gQD`WIGaWeJbGqHbxAOchMRcHYVdwAYexm\fhyZgYIahIUdgiahiYmkjIenkJAqkzMolj]v_Jizmzu}njn@okJCp[VAqKfHq{rKq[~OsLJRs|BUt|]?ulnZv\z]u}FawmRdx]Jgy]fjzMrhz~Bo
:~?@s_GE@_wQC_W]GaGiJawaMbw}PchINdXYUeHeXdhq\fX}_gHubhIQehy]ciimjjYymizEqkjQtlZIwmZeznJqxn{B?okNBoKZFp{fIqk^LrkzOs\FMtLVTt|bWt\n[vLz^v|raw}NdxmZby]jizMvlynBp{^
:~?@t_GEA_gQD`WIGaWeJbGqHbxAOchMRcHYVdxeYeh]\fhy_gYE]_IUehiahiYYkjYunkJAlkzQslj]vlJizmzu}njn@okJCp[VA_GBIq{nLrkzJs\JQtLVTslbXu\n[vLf^wMBaw}N_xm^fy]jix}vmznBp{]z
:~?@u_GEA_gQD`WcAAGaIawmLbgyJcXIQdHUTchaXeWa[fXu^gIA\gyQchi]fhIijiwamjy}pkjInlZYumJexljq|nWB?o[FBpKR@p{bGqknJqKzNrwBQs|NTtlZRu\jYvLv\umB`wWBcx]VfyMbdy}rkzm~nzNJr{~
:~?@v_GA?_wQC`g]F`GiJawuMbgmPchISdXUQeHeXexq[eX}_gIIbgyAehy]hiiifjYymkJEpjjQtlZ]wmJUznJq}nz}{okNBp[ZEo{fIqkrLr[jOs\FRtLRPt|bWulnZuLz^v}Fawl~dxmZgy]fezMvlz~Boz^Ns|N
:~?@w_GE@_wQC_W]GaGiJawaMbw}PchINdXYUeHeXdhq\fX}_gHubhIQehy]ciimjjYymizEqkjQtlZIwmZeznJqxn{B?okNBoKZFp{fIqk^LrkzOs\FMtLVTt|bWt\n[vLz^v|raw}NdxmZby]jizMvlynBp{^Ns|NF
:~?@x_GEA_gQD`WIGaWeJbGqOAO}NcXIQdHUTchaXeXm[fHe^gIAagyM_hi]fiYiihw}NjzAokjMrkJYvlzeymj]|njz?o[E}_KVEpkbHq[ZKr[vNsLBLs|RStl^VtLjZu|v]vlm?_MNcxMZfx}Riy}nlzmzj{^Jq|NVt{n
:~?@y_GEA_gQD`WIGaWeJbGqHbxAOchMRcHYVdxeYeh]\fhy?gYIahIUdgiahiYmkjIenkJAqkzMolj]vmZiylzu}ngB@okJCp[VAqKfHq{rKq[~OsLJRs|BUt|^XuljVv\z]_MFawmRdx]Jgy]fjzMrhz~Bo{nNr{NZv|~
:~?@z_GE@_wQC_W]GaGiJawaMbw}PchINdXYUeHeXdhq\fX}_gHubhIQehy]ciimjjYymizEqkjQtlZIwmZeznJqxn{B?okNBoKZFp{fIqk^LrkzOs\FMtLVTt|bWt\n[vLz^v|raw}NdxmZby]jizMvlynBp{^Ns|NFv}Nb
:~?@{_GEA_gQD`WIGaWeJbGqHbxAOchMRcHYVdxeYeh]\fhy_gYE]_IUehiahiYYkjYunkJAlkzQslj]vlJizmzu}njn@okJCp[VAqKfHq{rKqWA?s\JQtLVTslbXu\n[vLf^wMBaw}N_xm^fy]jix}vmznBp{]zs|^Vv}Nbt
:~?@|_GEA_gQD`WIGaWeJbGqOAO}NcXIQdHUTchaXeXm[fHe^gIANgyQchi]fhIijiyumjimpkjINlZYumJexljq|nZ~?oJvBpKQ?p{bGqknJqKzNr|FQsk~TtlY?u\jYvLv\umB`w]NcxMFfyMa?y}rkzm~nzNJr{~Vu|nNx}nj
:~?@}_GA?_wQC`g]F`GiJawuMbgmPchISdXUQeHeXexq[eX}_gIIbgyAehy]hiiifjYymkJEpjjQtlZ]wmJUznJq}nz}{okNBp[ZEo{fIqkrLr[jOs\FRtLRPt|bWulnZuLz^v}Fawl~dxmZgy]fezMvlz~Boz^Ns|NZv|~Ry}~n
:~?@~_GE@_wQC_W]GaGiJawaMbw}PchINdXYUeHeXdhq\fX}_gHubhIQehy]ciimjjYymizEqkjQtlZIwmZeznJqxn{B?okNBoKZFp{fIqk^LrkzOs\FMtLVTt|bWt\n[vLz^v|raw}NdxmZby]jizMvlynBp{^Ns|NFv}Nby}~nw
:~?A?_GEA_gQD`WIGaWeJbGqOAO}NcXIQdHUTchaXeXm[fHe^gIAagyM_hi]fiYiihw}NjzAokjMrkJYvlzeymj]|njz?o[E}_KVEpkbHq[ZKr[vNsLBLs|RStl^VtLjZu|v]vlm?_MNcxMZfx}Riy}nlzmzj{^Jq|NVt{nbx}^n{~Nf
:~?A@_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]_C`cSaccdckadChdKjdckdKneCoeSre[oesve{xfSye{|fs}_D@gTAgdDglAhDHhLJhdKhLNiDOiTRi\OitVi|XjTYi|\jt]_D`kTakddklalDhlLjldklLnmDomTrm\omtvm|xnTym||nt}
:~?AA_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n~
:~?AB_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgck?dcldkneCodkrecsesve{sfSzf[|fs}f\@gTAgdDglAhDHhLJhdKhLNiDOiTRi\O_C?jDXjLZjd[jL^kD_kTbk\_ktfk|hlTik|lltmmDpmLmmdtmlvnDwmlznd{nt~n|{
:~?AC_C@_SA_cD_kA`CH`KJ`cKa?H@{NaKQaSSakTaSWbKXb[[bcXb{_cCNc[cccec{fccid[jdkmdsjeKqeSNekueswfKxes{fk|f|?gC|g\Cgc?g|GhDIh\JhDMh|NiLQiTNilUitWjLXit[jl\_D_kL`k\ckd`k|glDil\jlDml|n_Dqm\rmlumtrnLynT{nl|nU?oM@
:~?AD_C?_CB_cC_sF_{C`SJ`[L`sM`[PaSQacTakQbCXbKZbc[bK^cC_cSbc[_csfc{hdSic{ldsmeCpeKmectekvfCwekzfc{fs~f{{gTBg\DgtEg\HhTIhdLhlIiDPiLRidSiLVjDWjTZj\Wjt^j|`kTaj|dktelDhlLeldlllnmDollrmdsmtvm|snTzn\|nt}n]@oUA
:~?AE_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn~
:~?AF_C@_SA_cD_kA`CH`KJ`cKa?H@{NaKQaSSakTaSWbKXb[[bcXb{_cCac[bcCec{fdKidSf`{Nd{oeCqe[reCue{vfKyfSvfk}ft?gL@ftCglDg|GhDD_DKhlLh|OiDLi\SidUi|VidYj\Zjl]jtZkLakTckldkS?_Dil\jllmltjmLqmTsmltmTwnLxn\{ndxn}?oEAo]BoF
:~?AG_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]_C`cSaccdckadChdKjdckdKneCoeSre[oesve{xfSye{|fs}_D@gTAgdDglAhDHhLJhdKhLNiDOiTRi\OitVi|XjTYi|\jt]kD`kL]kddkk?lDhlLjldklLnmDomTrm\omtvm|xnTym||nt}oE@oL}oeDon
:~?AH_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouE
:~?AI_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgck?dcldkneCodkrecsesve{sfSzf[|fs}f\@gTAgdDglAhDHhLJhdKhLNiDOiTRi\O_C?jDXjLZjd[jL^kD_kTbk\_ktfk|hlTik|lltmmDpmLmmdtmlvnDwmlznd{nt~n|{oUBo]DouEo^
:~?AJ_C@_SA_cD_kA`CH`KJ`cKa?H@{NaKQaSSakTaSWbKXb[[bcXb{_cCac[bcCec{f`{id[jdkmdsjeKqeSsekteSwfKx`{{fk|f|?gC|g\CgdEg|FgdIh\J_DMh|NiLQiTNilUitWjLXit[jl\j|_kD\k\ckc?k|glDil\jlDml|nmLqmTnmlums?nLynT{nl|nU?oM@o]Coe@o}GpF
:~?AK_C?_CB_cC_sF_{C`SJ`[L`sM`[PaSQacTakQbCXbKZbc[bK^cC_cSbc[_csfc{hdSic{ldsmeCpeKmectekvfCwekzfc{fs~f{{gTBg\DgtEg\HhTIhdLhlIiDPiLRidSiLVjDWjTZj\Wjt^j|`kTaj|dktelDhlLeldlllnmDollrmdsmtvm|snTzn\|nt}n]@oUAoeDomApEHpN
:~?AL_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpME
:~?AM_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[VA?UasWbKXb[[bcXb{_cCac[bcCec{fdKidSfdkmdsoeKpdsUasue{vfKyfSvfk}ft?gL@ftCglDg|GhDDh\KhdMh|Nhc?i\SidUi|VidYj\Zjl]jtZkLakTckldkTglLhl\kldh_C?mLqmTsmltmTwnLxn\{ndxn}?oEAo]BoEEo}FpMIpUF
:~?AN_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]_C`cSaccdckadChdKjdckdKneCoeSre[oesve{xfSye{|fs}gD@gK}gdDgk?hDHhLJhdKhLNiDOiTRi\OitVi|XjTYi|\jt]kD`kL]kddklflDgkljldk_DnmDomTrm\omtvm|xnTym||nt}oE@oL}oeDomFpEGomJpeK
:~?AO_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpn
:~?AP_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgck?dcldkneCodkrecsesve{sfSzf[|fs}f\@gTAgdDglAhDHhLJhdKhLNiDOiTRi\OitVi|XjTYi{?_D^kD_kTbk\_ktfk|hlTik|lltmmDpmLmmdtmlvnDwmlznd{nt~n|{oUBo]DouEo]HpUIpeLpmI
:~?AQ_C@_SA_cD_kA`CH`KJ`cKa?H@{NaKQaSSakTaSWbKXb[[bcXb{_cCac[bcCec{f`{id[jdkmdsjeKqeSsekteSwfKx`{{fk|f|?gC|g\CgdEg|FgdIh\J_DMh|NiLQiTNilUitWjLXit[jl\j|_kD\k\ckc?k|glDil\jlDml|nmLqmTnmlums?nLynT{nl|nU?oM@o]Coe@o}GpEIp]JpEMp}N
:~?AR_C?_CB_cC_sF_{C`SJ`[L`sM`[PaSQacTakQbCXbKZbc[bK^cC_cSbc[_csfc{hdSic{ldsmeCpeKmectekvfCwekzfc{fs~f{{gTBg\DgtEg\HhTIhdLhlIiDPiLRidSiLVjDWjTZj\Wjt^j|`kTaj|dktelDhlLeldlllnmDollrmdsmtvm|snTzn\|nt}n]@oUAoeDomApEHpMJpeKpMNqEO
:~?AS_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpn
:~?AT_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[VA?UasWbKXb[[bcXb{_cCac[bcCec{fdKidSfdkmdsoeKpdsUasue{vfKyfSvfk}ft?gL@ftCglDg|GhDDh\KhdMh|Nhc?i\SidUi|VidYj\Zjl]jtZkLakTckldkTglLhl\kldhl|omDqm\rmC?_DwnLxn\{ndxn}?oEAo]BoEEo}FpMIpUFpmMpuOqMPpv
:~?AU_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdck?dChdKjdckdKneCoeSre[oesve{xfSye{|fs}gD@gK}gdDglFhDGglJhdK_DNiDOiTRi\OitVi|XjTYi|\jt]kD`kL]kddklflDgkljldkltnl|kmTrm[?mtvm|xnTym||nt}oE@oL}oeDomFpEGomJpeKpuNp}KqURq^
:~?AV_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeS
:~?AW_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgckjdckdsnd{k_Crecsesve{sfSzf[|fs}f\@gTAgdDglAhDHhLJhdKhLNiDOiTRi\OitVi|XjTYi|\jt]kD`kL]_C?ktfk|hlTik|lltmmDpmLmmdtmlvnDwmlznd{nt~n|{oUBo]DouEo]HpUIpeLpmIqEPqMRqeSqN
:~?AX_C@_SA_cD_kA`CH`KJ`cKa?H@{NaKQaSSakTaSWbKXb[[bcXb{_cCac[bcCec{f`{id[jdkmdsjeKqeSsekteSwfKxf[{fcxf|?gCNg\CgdEg|FgdIh\JhlMhtJiLQiS?ilUitWjLXit[jl\j|_kD\k\ckdek|fkdil\j_Dml|nmLqmTnmlumtwnLxmt{nl|_E?oM@o]Coe@o}GpEIp]JpEMp}NqMQqUNqmUqv
:~?AY_C?_CB_cC_sF_{C`SJ`[L`sM`[PaSQacTakQbCXbKZbc[bK^cC_cSbc[_csfc{hdSic{ldsmeCpeKmectekvfCwekzfc{fs~f{{gTBg\DgtEg\HhTIhdLhlIiDPiLRidSiLVjDWjTZj\Wjt^j|`kTaj|dktelDhlLeldlllnmDollrmdsmtvm|snTzn\|nt}n]@oUAoeDomApEHpMJpeKpMNqEOqURq]OquVq~
:~?AZ_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}S
:~?A[_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[VA?UasWbKXb[[bcXb{_cCac[bcCec{fdKidSfdkmdsoeKpdssekte{wfCtasUfk}ft?gL@ftCglDg|GhDDh\KhdMh|NhdQi\RilUitR_DYj\Zjl]jtZkLakTckldkTglLhl\kldhl|omDqm\rmDum|vnLynTv_C?n}?oEAo]BoEEo}FpMIpUFpmMpuOqMPpuSqmTq}WrET
:~?A\_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdck?dChdKjdckdKneCoeSre[oesve{xfSye{|fs}gD@gK}gdDglFhDGglJhdK_DNiDOiTRi\OitVi|XjTYi|\jt]kD`kL]kddklflDgkljldkltnl|kmTrm[?mtvm|xnTym||nt}oE@oL}oeDomFpEGomJpeKpuNp}KqURq]TquUq]XrUY
:~?A]_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr^
:~?A^_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgckjdckdsnd{k_Crecsesve{sfSzf[|fs}f\@gTAgdDglAhDHhLJhdKhLNiDOiTRi\OitVi|XjTYi|\jt]kD`kL]_C?ktfk|hlTik|lltmmDpmLmmdtmlvnDwmlznd{nt~n|{oUBo]DouEo]HpUIpeLpmIqEPqMRqeSqMVrEWrUZr]W
:~?A__C@_SA_cD_kA`CH`KJ`cKa?H@{NaKQaSSakTaSWbKXb[[bcXb{_cCac[bcCec{f`{id[jdkmdsjeKqeSsekteSwfKxf[{fcxf|?gCNg\CgdEg|FgdIh\JhlMhtJiLQiS?ilUitWjLXit[jl\j|_kD\k\ckdek|fkdil\j_Dml|nmLqmTnmlumtwnLxmt{nl|n}?oD|o]Coc?o}GpEIp]JpEMp}NqMQqUNqmUquWrMXqu[rm\
:~?A`_C?_CB_cC_sF_{C`SJ`[L`sM`[PaSQacTakQbCXbKZbc[bK^cC_cSbc[_csfc{hdSic{ldsmeCpeKmectekvfCwekzfc{fs~f{{gTBg\DgtEg\HhTIhdLhlIiDPiLRidSiLVjDWjTZj\Wjt^j|`kTaj|dktelDhlLeldlllnmDollrmdsmtvm|snTzn\|nt}n]@oUAoeDomApEHpMJpeKpMNqEOqURq]OquVq}XrUYq}\ru]
:~?Aa_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr]\ru]r^
:~?Ab_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[VA?UasWbKXb[[bcXb{_cCac[bcCec{fdKidSfdkmdsoeKpdssekte{wfCtasUfk}ft?gL@ftCglDg|GhDDh\KhdMh|NhdQi\RilUitR_DYj\Zjl]jtZkLakTckldkTglLhl\kldhl|omDqm\rmDum|vnLynTv_C?n}?oEAo]BoEEo}FpMIpUFpmMpuOqMPpuSqmTq}WrETr][re]r}^rf
:~?Ac_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdck?dChdKjdckdKneCoeSre[oesve{xfSye{|fs}gD@gK}gdDglFhDGglJhdK_DNiDOiTRi\OitVi|XjTYi|\jt]kD`kL]kddklflDgkljldkltnl|kmTrm\tmtum\xnTy_D|nt}oE@oL}oeDomFpEGomJpeKpuNp}KqURq]TquUq]XrUYre\rmYsE`sN
:~?Ad_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr]\ru]r]`sUa
:~?Ae_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgckjdckdsnd{k_Crecsesve{sfSzf[|fs}f\@gTAgdDglAhDHhLJhdKhLNiDOiTRi\OitVi|XjTYi|\jt]kD`kL]kddklflDgkk?_DlltmmDpmLmmdtmlvnDwmlznd{nt~n|{oUBo]DouEo]HpUIpeLpmIqEPqMRqeSqMVrEWrUZr]Wru^r}`sUar~
:~?Af_C@_SA_cD_kA`CH`KJ`cKa?H@{NaKQaSSakTaSWbKXb[[bcXb{_cCac[bcCec{f`{id[jdkmdsjeKqeSsekteSwfKxf[{fcxf|?gCNg\CgdEg|FgdIh\JhlMhtJiLQiTSilTiTWjLX_D[jl\j|_kD\k\ckdek|fkdil\jllmltjmLqmS?mlumtwnLxmt{nl|n}?oD|o]CoeEo}FoeIp]J_EMp}NqMQqUNqmUquWrMXqu[rm\r}_sE\s]csf
:~?Ag_C?_CB_cC_sF_{C`SJ`[L`sM`[PaSQacTakQbCXbKZbc[bK^cC_cSbc[_csfc{hdSic{ldsmeCpeKmectekvfCwekzfc{fs~f{{gTBg\DgtEg\HhTIhdLhlIiDPiLRidSiLVjDWjTZj\Wjt^j|`kTaj|dktelDhlLeldlllnmDollrmdsmtvm|snTzn\|nt}n]@oUAoeDomApEHpMJpeKpMNqEOqURq]OquVq}XrUYq}\ru]sE`sM]sedsn
:~?Ah_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr]\ru]r]`sUasedsma
:~?Ai_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[VA?UasWbKXb[[bcXb{_cCac[bcCec{fdKidSfdkmdsoeKpdssekte{wfCtasUfk}ft?gL@ftCglDg|GhDDh\KhdMh|NhdQi\RilUitRjLYjT[jl\jS?kLakTckldkTglLhl\kldhl|omDqm\rmDum|vnLynTvnl}nu?oM@ns?_EEo}FpMIpUFpmMpuOqMPpuSqmTq}WrETr][re]r}^reas]bsmesub
:~?Aj_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdck?dChdKjdckdKneCoeSre[oesve{xfSye{|fs}gD@gK}gdDglFhDGglJhdKhtNh|KiTRi[?itVi|XjTYi|\jt]kD`kL]kddklflDgkljldkltnl|kmTrm\tmtum\xnTynd|nlyoE@oK?oeDomFpEGomJpeKpuNp}KqURq]TquUq]XrUYre\rmYsE`sMbsecsMftEg
:~?Ak_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr]\ru]r]`sUasedsmatEhtN
:~?Al_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgckjdckdsnd{keSre[tesue[?fSzf[|fs}f\@gTAgdDglAhDHhLJhdKhLNiDOiTRi\OitVi|XjTYi|\jt]kD`kL]kddklflDgkljldkltnl|k_C?mdtmlvnDwmlznd{nt~n|{oUBo]DouEo]HpUIpeLpmIqEPqMRqeSqMVrEWrUZr]Wru^r}`sUar}dsuetEhtMe
:~?Am_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[VA?UasWbKXb[[bcXb{_cCac[bcCec{fdKidSfdkmdsUeKqeSsekteSwfKxf[{fcxf|?gDAg\BgDEg|FatIh\JhlMhtJiLQiTSilTiTWjLXj\[jdXj|_kC?k\ckdek|fkdil\jllmltjmLqmTsmltmTwnLx_D{nl|n}?oD|o]CoeEo}FoeIp]JpmMpuJqMQqS?qmUquWrMXqu[rm\r}_sE\s]csees}fseit]j
:~?An_C?_CB_cC_sF_{C`SJ`[L`sM`[PaSQacTakQbCXbKZbc[bK^cC_cSbc[_csfc{hdSic{ldsmeCpeKmectekvfCwekzfc{fs~f{{gTBg\DgtEg\HhTIhdLhlIiDPiLRidSiLVjDWjTZj\Wjt^j|`kTaj|dktelDhlLeldlllnmDollrmdsmtvm|snTzn\|nt}n]@oUAoeDomApEHpMJpeKpMNqEOqURq]OquVq}XrUYq}\ru]sE`sM]sedsmftEgsmjtek
:~?Ao_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr]\ru]r]`sUasedsmatEhtMjtektN
:~?Ap_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYboVBk\b{_cCac[bcCec{fdKidSfdkmdsoeKpdssekte{wfCtf[{fc}f{~fc\blCglDg|GhDDh\KhdMh|NhdQi\RilUitRjLYjT[jl\jT_kL`k\ckd`_DglLhl\kldhl|omDqm\rmDum|vnLynTvnl}nu?oM@nuComDo}GpED_C?pmMpuOqMPpuSqmTq}WrETr][re]r}^reas]bsmesubtMitUktmltV
:~?Aq_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgckjdck_CneCoeSre[oesve{xfSye{|fs}gD@gK}gdDglFhDGglJhdKhtNh|KiTRi\TitUi\XjTY_D\jt]kD`kL]kddklflDgkljldkltnl|kmTrm\tmtum\xnTynd|nlyoE@oMBoeCoMFpEG_EJpeKpuNp}KqURq]TquUq]XrUYre\rmYsE`sMbsecsMftEgtUjt]gtunt~
:~?Ar_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr]\ru]r]`sUasedsmatEhtMjtektMnuEo
:~?As_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgckjdckdsnd{keSre[tesue[?fSzf[|fs}f\@gTAgdDglAhDHhLJhdKhLNiDOiTRi\OitVi|XjTYi|\jt]kD`kL]kddklflDgkljldkltnl|k_C?mdtmlvnDwmlznd{nt~n|{oUBo]DouEo]HpUIpeLpmIqEPqMRqeSqMVrEWrUZr]Wru^r}`sUar}dsuetEhtMeteltmnuEotn
:~?At_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[VA?UasWbKXb[[bcXb{_cCac[bcCec{fdKidSfdkmdsUeKqeSsekteSwfKxf[{fcxf|?gDAg\BgDEg|FatIh\JhlMhtJiLQiTSilTiTWjLXj\[jdXj|_kC?k\ckdek|fkdil\jllmltjmLqmTsmltmTwnLxn\{ndxn}?oC?o]CoeEo}FoeIp]JpmMpuJqMQqUSqmTqUWrMX_E[rm\r}_sE\s]csees}fseit]jtmmtujuMquV
:~?Au_C?_CB_cC_sF_{C`SJ`[L`sM`[PaSQacTakQbCXbKZbc[bK^cC_cSbc[_csfc{hdSic{ldsmeCpeKmectekvfCwekzfc{fs~f{{gTBg\DgtEg\HhTIhdLhlIiDPiLRidSiLVjDWjTZj\Wjt^j|`kTaj|dktelDhlLeldlllnmDollrmdsmtvm|snTzn\|nt}n]@oUAoeDomApEHpMJpeKpMNqEOqURq]OquVq}XrUYq}\ru]sE`sM]sedsmftEgsmjtektunt}kuUru^
:~?Av_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr]\ru]r]`sUasedsmatEhtMjtektMnuEouUru]o
:~?Aw_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYboVBk\b{_cCac[bcCec{fdKidSfdkmdsoeKpdssekte{wfCtf[{fc}f{~fc\blCglDg|GhDDh\KhdMh|NhdQi\RilUitRjLYjT[jl\jT_kL`k\ckd`_DglLhl\kldhl|omDqm\rmDum|vnLynTvnl}nu?oM@nuComDo}GpEDp]KpeMp}Npc?_ESqmTq}WrETr][re]r}^reas]bsmesubtMitUktmltUouMpu]suep
:~?Ax_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgckjdck_CneCoeSre[oesve{xfSye{|fs}gD@gK}gdDglFhDGglJhdKhtNh|KiTRi\TitUi\XjTY_D\jt]kD`kL]kddklflDgkljldkltnl|kmTrm\tmtum\xnTynd|nlyoE@oMBoeCoMFpEG_EJpeKpuNp}KqURq]TquUq]XrUYre\rmYsE`sMbsecsMftEgtUjt]gtunt}puUqt}tuuu
:~?Ay_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr]\ru]r]`sUasedsmatEhtMjtektMnuEouUru]ouuvu~
:~?Az_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgckjdckdsnd{keSre[tesue[?fSzf[|fs}f\@gTAgdDglAhDHhLJhdKhLNiDOiTRi\OitVi|XjTYi|\jt]kD`kL]kddklflDgkljldkltnl|kmTrm\tmtum[?_Dznd{nt~n|{oUBo]DouEo]HpUIpeLpmIqEPqMRqeSqMVrEWrUZr]Wru^r}`sUar}dsuetEhtMeteltmnuEotmruesuuvu}s
:~?A{_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[VA?UasWbKXb[[bcXb{_cCac[bcCec{fdKidSfdkmdsoeKpdssektaswfKxf[{fcxf|?gDAg\BgDEg|FhLIhTFhlMhsUiLQiTSilTiTWjLXj\[jdXj|_kDak\bkDek|f_Dil\jllmltjmLqmTsmltmTwnLxn\{ndxn}?oEAo]BoEEo}F_EIp]JpmMpuJqMQqUSqmTqUWrMXr][reXr}_sC?s]csees}fseit]jtmmtujuMquUsumtuUwvMx
:~?A|_C?_CB_cC_sF_{C`SJ`[L`sM`[PaSQacTakQbCXbKZbc[bK^cC_cSbc[_csfc{hdSic{ldsmeCpeKmectekvfCwekzfc{fs~f{{gTBg\DgtEg\HhTIhdLhlIiDPiLRidSiLVjDWjTZj\Wjt^j|`kTaj|dktelDhlLeldlllnmDollrmdsmtvm|snTzn\|nt}n]@oUAoeDomApEHpMJpeKpMNqEOqURq]OquVq}XrUYq}\ru]sE`sM]sedsmftEgsmjtektunt}kuUru]tuuuu]xvUy
:~?A}_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr]\ru]r]`sUasedsmatEhtMjtektMnuEouUru]ouuvu}xvUyu~
:~?A~_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYboVBk\b{_cCac[bcCec{fdKidSfdkmdsoeKpdssekte{wfCtf[{fc}f{~fdAg\BglEgtBbk\h\KhdMh|NhdQi\RilUitRjLYjT[jl\jT_kL`k\ckd`k|glDil\jlC?l|omDqm\rmDum|vnLynTvnl}nu?oM@nuComDo}GpEDp]KpeMp}NpeQq]RqmUquR_C?r][re]r}^reas]bsmesubtMitUktmltUouMpu]suepu}wvEyv]zvF
:~?B?_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgckjdck_CneCoeSre[oesve{xfSye{|fs}gD@gK}gdDglFhDGglJhdKhtNh|KiTRi\TitUi\XjTY_D\jt]kD`kL]kddklflDgkljldkltnl|kmTrm\tmtum\xnTynd|nlyoE@oMBoeCoMFpEGpUJp]GpuNp{?qURq]TquUq]XrUYre\rmYsE`sMbsecsMftEgtUjt]gtunt}puUqt}tuuuvExvMuve|vn
:~?B@_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr]\ru]r]`sUasedsmatEhtMjtektMnuEouUru]ouuvu}xvUyu}|vu}
:~?BA_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgckjdckdsnd{keSre[tesue[xfSyfc|fky_D@gTAgdDglAhDHhLJhdKhLNiDOiTRi\OitVi|XjTYi|\jt]kD`kL]kddklflDgkljldkltnl|kmTrm\tmtum\xnTynd|nly_C?oUBo]DouEo]HpUIpeLpmIqEPqMRqeSqMVrEWrUZr]Wru^r}`sUar}dsuetEhtMeteltmnuEotmruesuuvu}svUzv]|vu}v^
:~?BB_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[VA?UasWbKXb[[bcXb{_cCac[bcCec{fdKidSfdkmdsoeKpdssektaswfKxf[{fcxf|?gDAg\BgDEg|FhLIhTFhlMhsUiLQiTSilTiTWjLXj\[jdXj|_kDak\bkDek|f_Dil\jllmltjmLqmTsmltmTwnLxn\{ndxn}?oEAo]BoEEo}F_EIp]JpmMpuJqMQqUSqmTqUWrMXr][reXr}_sC?s]csees}fseit]jtmmtujuMquUsumtuUwvMxv]{vexv~?wF
:~?BC_C?_CB_cC_sF_{C`SJ`[L`sM`[PaSQacTakQbCXbKZbc[bK^cC_cSbc[_csfc{hdSic{ldsmeCpeKmectekvfCwekzfc{fs~f{{gTBg\DgtEg\HhTIhdLhlIiDPiLRidSiLVjDWjTZj\Wjt^j|`kTaj|dktelDhlLeldlllnmDollrmdsmtvm|snTzn\|nt}n]@oUAoeDomApEHpMJpeKpMNqEOqURq]OquVq}XrUYq}\ru]sE`sM]sedsmftEgsmjtektunt}kuUru]tuuuu]xvUyve|vmywF@wN
:~?BD_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr]\ru]r]`sUasedsmatEhtMjtektMnuEouUru]ouuvu}xvUyu}|vu}wF@wM}
:~?BE_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYboVBk\b{_cCac[bcCec{fdKidSfdkmdsoeKpdssekte{wfCtf[{fc}f{~fdAg\BglEgtBbk\h\KhdMh|NhdQi\RilUitRjLYjT[jl\jT_kL`k\ckd`k|glDil\jlC?l|omDqm\rmDum|vnLynTvnl}nu?oM@nuComDo}GpEDp]KpeMp}NpeQq]RqmUquR_C?r][re]r}^reas]bsmesubtMitUktmltUouMpu]suepu}wvEyv]zvE}v}~wNAwU~
:~?BF_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgckjdck_CneCoeSre[oesve{xfSye{|fs}gD@gK}gdDglFhDGglJhdKhtNh|KiTRi\TitUi\XjTYjd\jlYkD`kK?kddklflDgkljldkltnl|kmTrm\tmtum\xnTynd|nlyoE@oMBoeCoMFpEGpUJp]GpuNp}PqUQp}TquU_EXrUYre\rmYsE`sMbsecsMftEgtUjt]gtunt}puUqt}tuuuvExvMuve|vm~wF?vnBwfC
:~?BG_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr]\ru]r]`sUasedsmatEhtMjtektMnuEouUru]ouuvu}xvUyu}|vu}wF@wM}wfDwn
:~?BH_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgckjdckdsnd{keSre[tesue[xfSyfc|fky_D@gTAgdDglAhDHhLJhdKhLNiDOiTRi\OitVi|XjTYi|\jt]kD`kL]kddklflDgkljldkltnl|kmTrm\tmtum\xnTynd|nly_C?oUBo]DouEo]HpUIpeLpmIqEPqMRqeSqMVrEWrUZr]Wru^r}`sUar}dsuetEhtMeteltmnuEotmruesuuvu}svUzv]|vu}v^@wVAwfDwnA
:~?BI_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[VA?UasWbKXb[[bcXb{_cCac[bcCec{fdKidSfdkmdsoeKpdssektaswfKxf[{fcxf|?gDAg\BgDEg|FhLIhTFhlMhtOiLPhtSilTatWjLXj\[jdXj|_kDak\bkDek|flLilTfllmls?mLqmTsmltmTwnLxn\{ndxn}?oEAo]BoEEo}FpMIpUFpmMps?qMQqUSqmTqUWrMXr][reXr}_sEas]bsEes}f_Eit]jtmmtujuMquUsumtuUwvMxv]{vexv~?wFAw^BwFEw~F
:~?BJ_C?_CB_cC_sF_{C`SJ`[L`sM`[PaSQacTakQbCXbKZbc[bK^cC_cSbc[_csfc{hdSic{ldsmeCpeKmectekvfCwekzfc{fs~f{{gTBg\DgtEg\HhTIhdLhlIiDPiLRidSiLVjDWjTZj\Wjt^j|`kTaj|dktelDhlLeldlllnmDollrmdsmtvm|snTzn\|nt}n]@oUAoeDomApEHpMJpeKpMNqEOqURq]OquVq}XrUYq}\ru]sE`sM]sedsmftEgsmjtektunt}kuUru]tuuuu]xvUyve|vmywF@wNBwfCwNFxFG
:~?BK_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr]\ru]r]`sUasedsmatEhtMjtektMnuEouUru]ouuvu}xvUyu}|vu}wF@wM}wfDwnFxFGwn
:~?BL_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYboVBk\b{_cCac[bcCec{fdKidSfdkmdsoeKpdssekte{wfCtf[{fc}f{~fdAg\BglEgtBbk\h\KhdMh|NhdQi\RilUitRjLYjT[jl\jT_kL`k\ckd`k|glDil\jlDml|nmLqmTn_Dum|vnLynTvnl}nu?oM@nuComDo}GpEDp]KpeMp}NpeQq]RqmUquRrMYrU[rm\rS?_Eas]bsmesubtMitUktmltUouMpu]suepu}wvEyv]zvE}v}~wNAwU~wnEwvGxNHwv
:~?BM_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgckjdckdsnd{keSre[?esve{xfSye{|fs}gD@gK}gdDglFhDGglJhdKhtNh|KiTRi\TitUi\XjTYjd\jlYkD`kLbkdckLflDg_Djldkltnl|kmTrm\tmtum\xnTynd|nlyoE@oMBoeCoMFpEGpUJp]GpuNp}PqUQp}TquUrEXrMUre\rk?sE`sMbsecsMftEgtUjt]gtunt}puUqt}tuuuvExvMuve|vm~wF?vnBwfCwvFw~CxVJx^
:~?BN_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr]\ru]r]`sUasedsmatEhtMjtektMnuEouUru]ouuvu}xvUyu}|vu}wF@wM}wfDwnFxFGwnJxfK
:~?BO_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgckjdckdsnd{keSre[tesue[xfSyfc|fky_D@gTAgdDglAhDHhLJhdKhLNiDOiTRi\OitVi|XjTYi|\jt]kD`kL]kddklflDgkljldkltnl|kmTrm\tmtum\xnTynd|nlyoE@oMBoeCoK?_EHpUIpeLpmIqEPqMRqeSqMVrEWrUZr]Wru^r}`sUar}dsuetEhtMeteltmnuEotmruesuuvu}svUzv]|vu}v^@wVAwfDwnAxFHxNJxfKxN
:~?BP_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[VA?UasWbKXb[[bcXb{_cCac[bcCec{fdKidSfdkmdsoeKpdssektaswfKxf[{fcxf|?gDAg\BgDEg|FhLIhTFhlMhtOiLPhtSilTatWjLXj\[jdXj|_kDak\bkDek|flLilTfllmls?mLqmTsmltmTwnLxn\{ndxn}?oEAo]BoEEo}FpMIpUFpmMps?qMQqUSqmTqUWrMXr][reXr}_sEas]bsEes}ftMitUftmmts?uMquUsumtuUwvMxv]{vexv~?wFAw^BwFEw~FxNIxVFxnMxv
:~?BQ_C?_CB_cC_sF_{C`SJ`[L`sM`[PaSQacTakQbCXbKZbc[bK^cC_cSbc[_csfc{hdSic{ldsmeCpeKmectekvfCwekzfc{fs~f{{gTBg\DgtEg\HhTIhdLhlIiDPiLRidSiLVjDWjTZj\Wjt^j|`kTaj|dktelDhlLeldlllnmDollrmdsmtvm|snTzn\|nt}n]@oUAoeDomApEHpMJpeKpMNqEOqURq]OquVq}XrUYq}\ru]sE`sM]sedsmftEgsmjtektunt}kuUru]tuuuu]xvUyve|vmywF@wNBwfCwNFxFGxVJx^GxvNx~
:~?BR_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr]\ru]r]`sUasedsmatEhtMjtektMnuEouUru]ouuvu}xvUyu}|vu}wF@wM}wfDwnFxFGwnJxfKxvNx~K
:~?BS_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cKdBocccec{fdKidSfdkmdsoeKpdssekte{wfCtf[{fc}f{~fdAg\BglEgtBhLIhTKhlLhSccdQi\RilUitRjLYjT[jl\jT_kL`k\ckd`k|glDil\jlDml|nmLqmTnmlumtwnLxms?nl}nu?oM@nuComDo}GpEDp]KpeMp}NpeQq]RqmUquRrMYrU[rm\rU_sM`s]cse`_C?tMitUktmltUouMpu]suepu}wvEyv]zvE}v}~wNAwU~wnEwvGxNHwvKxnLx~OyFL
:~?BT_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgckjdckdsnd{keSre[?esve{xfSye{|fs}gD@gK}gdDglFhDGglJhdKhtNh|KiTRi\TitUi\XjTYjd\jlYkD`kLbkdckLflDg_Djldkltnl|kmTrm\tmtum\xnTynd|nlyoE@oMBoeCoMFpEGpUJp]GpuNp}PqUQp}TquUrEXrMUre\rk?sE`sMbsecsMftEgtUjt]gtunt}puUqt}tuuuvExvMuve|vm~wF?vnBwfCwvFw~CxVJx^LxvMx^PyVQ
:~?BU_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr]\ru]r]`sUasedsmatEhtMjtektMnuEouUru]ouuvu}xvUyu}|vu}wF@wM}wfDwnFxFGwnJxfKxvNx~KyVRy^
:~?BV_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgckjdckdsnd{keSre[tesue[xfSyfc|fkygD@gLBgdCgK?hDHhLJhdKhLNiDOiTRi\OitVi|XjTYi|\jt]kD`kL]kddklflDgkljldkltnl|kmTrm\tmtum\xnTynd|nlyoE@oMBoeCoMFpEGpUJp]G_C?qEPqMRqeSqMVrEWrUZr]Wru^r}`sUar}dsuetEhtMeteltmnuEotmruesuuvu}svUzv]|vu}v^@wVAwfDwnAxFHxNJxfKxNNyFOyVRy^O
:~?BW_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[VA?UasWbKXb[[bcXb{_cCac[bcCec{fdKidSfdkmdsoeKpdssektaswfKxf[{fcxf|?gDAg\BgDEg|FhLIhTFhlMhtOiLPhtSilTatWjLXj\[jdXj|_kDak\bkDek|flLilTfllmltomLpltsmlt_DwnLxn\{ndxn}?oEAo]BoEEo}FpMIpUFpmMpuOqMPpuSqmT_EWrMXr][reXr}_sEas]bsEes}ftMitUftmmtuouMptusumt_EwvMxv]{vexv~?wFAw^BwFEw~FxNIxVFxnMxvOyNPxvSynT
:~?BX_C?_CB_cC_sF_{C`SJ`[L`sM`[PaSQacTakQbCXbKZbc[bK^cC_cSbc[_csfc{hdSic{ldsmeCpeKmectekvfCwekzfc{fs~f{{gTBg\DgtEg\HhTIhdLhlIiDPiLRidSiLVjDWjTZj\Wjt^j|`kTaj|dktelDhlLeldlllnmDollrmdsmtvm|snTzn\|nt}n]@oUAoeDomApEHpMJpeKpMNqEOqURq]OquVq}XrUYq}\ru]sE`sM]sedsmftEgsmjtektunt}kuUru]tuuuu]xvUyve|vmywF@wNBwfCwNFxFGxVJx^GxvNx~PyVQx~TyvU
:~?BY_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr]\ru]r]`sUasedsmatEhtMjtektMnuEouUru]ouuvu}xvUyu}|vu}wF@wM}wfDwnFxFGwnJxfKxvNx~KyVRy^TyvUy^
:~?BZ_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cKdBocccec{fdKidSfdkmdsoeKpdssekte{wfCtf[{fc}f{~fdAg\BglEgtBhLIhTKhlLhSccdQi\RilUitRjLYjT[jl\jT_kL`k\ckd`k|glDil\jlDml|nmLqmTnmlumtwnLxms?nl}nu?oM@nuComDo}GpEDp]KpeMp}NpeQq]RqmUquRrMYrU[rm\rU_sM`s]cse`s}gtEit]jtC?_EouMpu]suepu}wvEyv]zvE}v}~wNAwU~wnEwvGxNHwvKxnLx~OyFLy^SyfUy~Vyf
:~?B[_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgckjdckdsnd{keSre[?esve{xfSye{|fs}gD@gK}gdDglFhDGglJhdKhtNh|KiTRi\TitUi\XjTYjd\jlYkD`kLbkdckLflDg_Djldkltnl|kmTrm\tmtum\xnTynd|nlyoE@oMBoeCoMFpEGpUJp]GpuNp}PqUQp}TquUrEXrMUre\rm^sE_rmbsec_EftEgtUjt]gtunt}puUqt}tuuuvExvMuve|vm~wF?vnBwfCwvFw~CxVJx^LxvMx^PyVQyfTynQzFXzN
:~?B\_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr]\ru]r]`sUasedsmatEhtMjtektMnuEouUru]ouuvu}xvUyu}|vu}wF@wM}wfDwnFxFGwnJxfKxvNx~KyVRy^TyvUy^XzVY
:~?B]_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgckjdckdsnd{keSre[tesue[xfSyfc|fkygD@gLBgdCgK?hDHhLJhdKhLNiDOiTRi\OitVi|XjTYi|\jt]kD`kL]kddklflDgkljldkltnl|kmTrm\tmtum\xnTynd|nlyoE@oMBoeCoMFpEGpUJp]G_C?qEPqMRqeSqMVrEWrUZr]Wru^r}`sUar}dsuetEhtMeteltmnuEotmruesuuvu}svUzv]|vu}v^@wVAwfDwnAxFHxNJxfKxNNyFOyVRy^OyvVy~XzVYy~
:~?B^_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYboVBk\b{_cCac[bcCec{fdKidSfdkmdsoeKpdssekte{wfCtf[{fc\f|?gDAg\BgDEg|FhLIhTFhlMhtOiLPhtSilTi|WjDTj\[jc\j|_kDak\bkDek|flLilTfllmltomLpltsmltm|wnDtn\{nc?n}?oEAo]BoEEo}FpMIpUFpmMpuOqMPpuSqmTq}WrETr][rc?r}_sEas]bsEes}ftMitUftmmtuouMptusumtu}wvEtv]{vc?v~?wFAw^BwFEw~FxNIxVFxnMxvOyNPxvSynTy~WzFTz^[zf
:~?B__C?_CB_cC_sF_{C`SJ`[L`sM`[PaSQacTakQbCXbKZbc[bK^cC_cSbc[_csfc{hdSic{ldsmeCpeKmectekvfCwekzfc{fs~f{{gTBg\DgtEg\HhTIhdLhlIiDPiLRidSiLVjDWjTZj\Wjt^j|`kTaj|dktelDhlLeldlllnmDollrmdsmtvm|snTzn\|nt}n]@oUAoeDomApEHpMJpeKpMNqEOqURq]OquVq}XrUYq}\ru]sE`sM]sedsmftEgsmjtektunt}kuUru]tuuuu]xvUyve|vmywF@wNBwfCwNFxFGxVJx^GxvNx~PyVQx~TyvUzFXzNUzf\zn
:~?B`_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr]\ru]r]`sUasedsmatEhtMjtektMnuEouUru]ouuvu}xvUyu}|vu}wF@wM}wfDwnFxFGwnJxfKxvNx~KyVRy^TyvUy^XzVYzf\znY
:~?Ba_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cKdBocccec{fdKidSfdkmdsoeKpdssekte{wfCtf[{fc}f{~fdAg\BglEgtBhLIhTKhlLhTOiLPi\SidPcccjLYjT[jl\jT_kL`k\ckd`k|glDil\jlDml|nmLqmTnmlumtwnLxmt{nl|n}?oD|_EComDo}GpEDp]KpeMp}NpeQq]RqmUquRrMYrU[rm\rU_sM`s]cse`s}gtEit]jtEmt}nuMquUn_C?u}wvEyv]zvE}v}~wNAwU~wnEwvGxNHwvKxnLx~OyFLy^SyfUy~VyfYz^Zzn]zvZ
:~?Bb_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgckjdckdsnd{keSre[?esve{xfSye{|fs}gD@gK}gdDglFhDGglJhdKhtNh|KiTRi\TitUi\XjTYjd\jlYkD`kLbkdckLflDglTjl\gltnl{?mTrm\tmtum\xnTynd|nlyoE@oMBoeCoMFpEGpUJp]GpuNp}PqUQp}TquUrEXrMUre\rm^sE_rmbsecsufs}ctUjt[?tunt}puUqt}tuuuvExvMuve|vm~wF?vnBwfCwvFw~CxVJx^LxvMx^PyVQyfTynQzFXzNZzf[zN^{F_
:~?Bc_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr]\ru]r]`sUasedsmatEhtMjtektMnuEouUru]ouuvu}xvUyu}|vu}wF@wM}wfDwnFxFGwnJxfKxvNx~KyVRy^TyvUy^XzVYzf\znY{F`{N
:~?Bd_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgckjdckdsnd{keSre[tesue[xfSyfc|fkygD@gLBgdCgK?hDHhLJhdKhLNiDOiTRi\OitVi|XjTYi|\jt]kD`kL]kddklflDgkljldkltnl|kmTrm\tmtum\xnTynd|nlyoE@oMBoeCoMFpEGpUJp]GpuNp}PqUQp{?_EVrEWrUZr]Wru^r}`sUar}dsuetEhtMeteltmnuEotmruesuuvu}svUzv]|vu}v^@wVAwfDwnAxFHxNJxfKxNNyFOyVRy^OyvVy~XzVYy~\zv]{F`{N]
:~?Be_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYboVBk\b{_cCac[bcCec{fdKidSfdkmdsoeKpdssekte{wfCtf[{fc\f|?gDAg\BgDEg|FhLIhTFhlMhtOiLPhtSilTi|WjDTj\[jc\j|_kDak\bkDek|flLilTfllmltomLpltsmltm|wnDtn\{nc?n}?oEAo]BoEEo}FpMIpUFpmMpuOqMPpuSqmTq}WrETr][re]r}^reas]b_Ees}ftMitUftmmtuouMptusumtu}wvEtv]{ve}v}~vfAw^B_FEw~FxNIxVFxnMxvOyNPxvSynTy~WzFTz^[zf]z~^zfa{^b
:~?Bf_C?_CB_cC_sF_{C`SJ`[L`sM`[PaSQacTakQbCXbKZbc[bK^cC_cSbc[_csfc{hdSic{ldsmeCpeKmectekvfCwekzfc{fs~f{{gTBg\DgtEg\HhTIhdLhlIiDPiLRidSiLVjDWjTZj\Wjt^j|`kTaj|dktelDhlLeldlllnmDollrmdsmtvm|snTzn\|nt}n]@oUAoeDomApEHpMJpeKpMNqEOqURq]OquVq}XrUYq}\ru]sE`sM]sedsmftEgsmjtektunt}kuUru]tuuuu]xvUyve|vmywF@wNBwfCwNFxFGxVJx^GxvNx~PyVQx~TyvUzFXzNUzf\zn^{F_znb{fc
:~?Bg_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr]\ru]r]`sUasedsmatEhtMjtektMnuEouUru]ouuvu}xvUyu}|vu}wF@wM}wfDwnFxFGwnJxfKxvNx~KyVRy^TyvUy^XzVYzf\znY{F`{Nb{fc{N
:~?Bh_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cKdBocccec{fdKidSfdkmdsoeKpdssekte{wfCtf[{fc}f{~fdAg\BglEgtBhLIhTKhlLhTOiLPi\SidPcccjLYjT[jl\jT_kL`k\ckd`k|glDil\jlDml|nmLqmTnmlumtwnLxmt{nl|n}?oD|_EComDo}GpEDp]KpeMp}NpeQq]RqmUquRrMYrU[rm\rU_sM`s]cse`s}gtEit]jtEmt}nuMquUn_C?u}wvEyv]zvE}v}~wNAwU~wnEwvGxNHwvKxnLx~OyFLy^SyfUy~VyfYz^Zzn]zvZ{Na{Vc{nd{V
:~?Bi_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgckjdckdsnd{keSre[tesue[xfSy_C|fs}gD@gK}gdDglFhDGglJhdKhtNh|KiTRi\TitUi\XjTYjd\jlYkD`kLbkdckLflDglTjl\gltnl|pmTql|tmtu_DxnTynd|nlyoE@oMBoeCoMFpEGpUJp]GpuNp}PqUQp}TquUrEXrMUre\rm^sE_rmbsecsufs}ctUjt]ltumt]puUq_EtuuuvExvMuve|vm~wF?vnBwfCwvFw~CxVJx^LxvMx^PyVQyfTynQzFXzNZzf[zN^{F_{Vb{^_{vf{~
:~?Bj_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr]\ru]r]`sUasedsmatEhtMjtektMnuEouUru]ouuvu}xvUyu}|vu}wF@wM}wfDwnFxFGwnJxfKxvNx~KyVRy^TyvUy^XzVYzf\znY{F`{Nb{fc{Nf|Fg
:~?Bk_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgckjdckdsnd{keSre[tesue[xfSyfc|fkygD@gLBgdCgLFhDGhTJh\G_DNiDOiTRi\OitVi|XjTYi|\jt]kD`kL]kddklflDgkljldkltnl|kmTrm\tmtum\xnTynd|nlyoE@oMBoeCoMFpEGpUJp]GpuNp}PqUQp}TquUrEXrMU_C?ru^r}`sUar}dsuetEhtMeteltmnuEotmruesuuvu}svUzv]|vu}v^@wVAwfDwnAxFHxNJxfKxNNyFOyVRy^OyvVy~XzVYy~\zv]{F`{N]{fd{nf|Fg{n
:~?Bl_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYboVBk\b{_cCac[bcCec{fdKidSfdkmdsoeKpdssekte{wfCtf[{fc}f{~fdAg\BblEg|FhLIhTFhlMhtOiLPhtSilTi|WjDTj\[jd]j|^jdak\bblek|flLilTfllmltomLpltsmltm|wnDtn\{nd}n|~neAo]B_EEo}FpMIpUFpmMpuOqMPpuSqmTq}WrETr][re]r}^reas]bsmesubtMitS?tmmtuouMptusumtu}wvEtv]{ve}v}~vfAw^BwnEwvBxNIxS?xnMxvOyNPxvSynTy~WzFTz^[zf]z~^zfa{^b{ne{vb|Ni|V
:~?Bm_C?_CB_cC_sF_{C`SJ`[L`sM`[PaSQacTakQbCXbKZbc[bK^cC_cSbc[_csfc{hdSic{ldsmeCpeKmectekvfCwekzfc{fs~f{{gTBg\DgtEg\HhTIhdLhlIiDPiLRidSiLVjDWjTZj\Wjt^j|`kTaj|dktelDhlLeldlllnmDollrmdsmtvm|snTzn\|nt}n]@oUAoeDomApEHpMJpeKpMNqEOqURq]OquVq}XrUYq}\ru]sE`sM]sedsmftEgsmjtektunt}kuUru]tuuuu]xvUyve|vmywF@wNBwfCwNFxFGxVJx^GxvNx~PyVQx~TyvUzFXzNUzf\zn^{F_znb{fc{vf{~c|Vj|^
:~?Bn_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr]\ru]r]`sUasedsmatEhtMjtektMnuEouUru]ouuvu}xvUyu}|vu}wF@wM}wfDwnFxFGwnJxfKxvNx~KyVRy^TyvUy^XzVYzf\znY{F`{Nb{fc{Nf|Fg|Vj|^g
:~?Bo_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cKdBocccec{fdKidSfdkmdsoeKpdssekte{wfCtf[{fc}f{~fdAg\BglEgtBhLIhTKhlLhTOiLPi\SidPcccjLYjT[jl\jT_kL`k\ckd`k|glDil\jlDml|nmLqmTnmlumtwnLxmt{nl|n}?oD|o]CoeEo}Foc?p]KpeMp}NpeQq]RqmUquRrMYrU[rm\rU_sM`s]cse`s}gtEit]jtEmt}nuMquUnumuuuwvMxus?_E}v}~wNAwU~wnEwvGxNHwvKxnLx~OyFLy^SyfUy~VyfYz^Zzn]zvZ{Na{Vc{nd{Vg|Nh|^k|fh
:~?Bp_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgckjdckdsnd{keSre[tesue[xfSy_C|fs}gD@gK}gdDglFhDGglJhdKhtNh|KiTRi\TitUi\XjTYjd\jlYkD`kLbkdckLflDglTjl\gltnl|pmTql|tmtu_DxnTynd|nlyoE@oMBoeCoMFpEGpUJp]GpuNp}PqUQp}TquUrEXrMUre\rm^sE_rmbsecsufs}ctUjt]ltumt]puUq_EtuuuvExvMuve|vm~wF?vnBwfCwvFw~CxVJx^LxvMx^PyVQyfTynQzFXzNZzf[zN^{F_{Vb{^_{vf{~h|Vi{~l|vm
:~?Bq_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr]\ru]r]`sUasedsmatEhtMjtektMnuEouUru]ouuvu}xvUyu}|vu}wF@wM}wfDwnFxFGwnJxfKxvNx~KyVRy^TyvUy^XzVYzf\znY{F`{Nb{fc{Nf|Fg|Vj|^g|vn|~
:~?Br_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgckjdckdsnd{keSre[tesue[xfSyfc|fkygD@gLBgdCgLFhDGhTJh\G_DNiDOiTRi\OitVi|XjTYi|\jt]kD`kL]kddklflDgkljldkltnl|kmTrm\tmtum\xnTynd|nlyoE@oMBoeCoMFpEGpUJp]GpuNp}PqUQp}TquUrEXrMU_C?ru^r}`sUar}dsuetEhtMeteltmnuEotmruesuuvu}svUzv]|vu}v^@wVAwfDwnAxFHxNJxfKxNNyFOyVRy^OyvVy~XzVYy~\zv]{F`{N]{fd{nf|Fg{nj|fk|vn|~k
:~?Bs_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYboVBk\b{_cCac[bcCec{fdKidSfdkmdsoeKpdssekte{wfCtf[{fc}f{~fdAg\BblEg|FhLIhTFhlMhtOiLPhtSilTi|WjDTj\[jd]j|^jdak\bblek|flLilTfllmltomLpltsmltm|wnDtn\{nd}n|~neAo]B_EEo}FpMIpUFpmMpuOqMPpuSqmTq}WrETr][re]r}^reas]bsmesubtMitS?tmmtuouMptusumtu}wvEtv]{ve}v}~vfAw^BwnEwvBxNIxS?xnMxvOyNPxvSynTy~WzFTz^[zf]z~^zfa{^b{ne{vb|Ni|Vk|nl|Vo}Np
:~?Bt_C?_CB_cC_sF_{C`SJ`[L`sM`[PaSQacTakQbCXbKZbc[bK^cC_cSbc[_csfc{hdSic{ldsmeCpeKmectekvfCwekzfc{fs~f{{gTBg\DgtEg\HhTIhdLhlIiDPiLRidSiLVjDWjTZj\Wjt^j|`kTaj|dktelDhlLeldlllnmDollrmdsmtvm|snTzn\|nt}n]@oUAoeDomApEHpMJpeKpMNqEOqURq]OquVq}XrUYq}\ru]sE`sM]sedsmftEgsmjtektunt}kuUru]tuuuu]xvUyve|vmywF@wNBwfCwNFxFGxVJx^GxvNx~PyVQx~TyvUzFXzNUzf\zn^{F_znb{fc{vf{~c|Vj|^l|vm|^p}Vq
:~?Bu_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr]\ru]r]`sUasedsmatEhtMjtektMnuEouUru]ouuvu}xvUyu}|vu}wF@wM}wfDwnFxFGwnJxfKxvNx~KyVRy^TyvUy^XzVYzf\znY{F`{Nb{fc{Nf|Fg|Vj|^g|vn|~p}Vq|~
:~?Bv_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgd_dD[jdkmdsoeKpdssekte{wfCtf[{fc}f{~fdAg\BglEgtBhLIhTKhlLhTOiLPi\SidPi|WjDYj\ZjCjd\_kL`k\ckd`k|glDil\jlDml|nmLqmTnmlumtwnLxmt{nl|n}?oD|o]CoeEo}FoeIp]JpmMpuJ_EQq]RqmUquRrMYrU[rm\rU_sM`s]cse`s}gtEit]jtEmt}nuMquUnumuuuwvMxuu{vm|v~?wE|_C?wnEwvGxNHwvKxnLx~OyFLy^SyfUy~VyfYz^Zzn]zvZ{Na{Vc{nd{Vg|Nh|^k|fh|~o}Fq}^r}F
:~?Bw_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgckjdckdsnd{keSre[tesue[xfSy_C|fs}gD@gK}gdDglFhDGglJhdKhtNh|KiTRi\TitUi\XjTYjd\jlYkD`kLbkdckLflDglTjl\gltnl|pmTql|tmtu_DxnTynd|nlyoE@oMBoeCoMFpEGpUJp]GpuNp}PqUQp}TquUrEXrMUre\rm^sE_rmbsecsufs}ctUjt]ltumt]puUquetumqvExvK?ve|vm~wF?vnBwfCwvFw~CxVJx^LxvMx^PyVQyfTynQzFXzNZzf[zN^{F_{Vb{^_{vf{~h|Vi{~l|vm}Fp}Nm}ft}n
:~?Bx_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr]\ru]r]`sUasedsmatEhtMjtektMnuEouUru]ouuvu}xvUyu}|vu}wF@wM}wfDwnFxFGwnJxfKxvNx~KyVRy^TyvUy^XzVYzf\znY{F`{Nb{fc{Nf|Fg|Vj|^g|vn|~p}Vq|~t}vu
:~?By_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgckjdckdsnd{keSre[tesue[xfSyfc|fkygD@gLBgdCgLFhDGhTJh\G_DNiDOiTRi\OitVi|XjTYi|\jt]kD`kL]kddklflDgkljldkltnl|kmTrm\tmtum\xnTynd|nlyoE@oMBoeCoMFpEGpUJp]GpuNp}PqUQp}TquUrEXrMUre\rm^sE_rk?_EdsuetEhtMeteltmnuEotmruesuuvu}svUzv]|vu}v^@wVAwfDwnAxFHxNJxfKxNNyFOyVRy^OyvVy~XzVYy~\zv]{F`{N]{fd{nf|Fg{nj|fk|vn|~k}Vr}^t}vu}^
:~?Bz_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYboVBk\b{_cCac[bcCec{fdKidSfdkmdsoeKpdssekte{wfCtf[{fc}f{~fdAg\BblEg|FhLIhTFhlMhtOiLPhtSilTi|WjDTj\[jd]j|^jdak\bklektblLilS\llmltomLpltsmltm|wnDtn\{nd}n|~neAo]BomEouBpMIpS?pmMpuOqMPpuSqmTq}WrETr][re]r}^reas]bsmesubtMitUktmltUouMp_Esumtu}wvEtv]{ve}v}~vfAw^BwnEwvBxNIxVKxnLxVOyNP_FSynTy~WzFTz^[zf]z~^zfa{^b{ne{vb|Ni|Vk|nl|Vo}Np}^s}fp}~w~F
:~?B{_C?_CB_cC_sF_{C`SJ`[L`sM`[PaSQacTakQbCXbKZbc[bK^cC_cSbc[_csfc{hdSic{ldsmeCpeKmectekvfCwekzfc{fs~f{{gTBg\DgtEg\HhTIhdLhlIiDPiLRidSiLVjDWjTZj\Wjt^j|`kTaj|dktelDhlLeldlllnmDollrmdsmtvm|snTzn\|nt}n]@oUAoeDomApEHpMJpeKpMNqEOqURq]OquVq}XrUYq}\ru]sE`sM]sedsmftEgsmjtektunt}kuUru]tuuuu]xvUyve|vmywF@wNBwfCwNFxFGxVJx^GxvNx~PyVQx~TyvUzFXzNUzf\zn^{F_znb{fc{vf{~c|Vj|^l|vm|^p}Vq}ft}nq~Fx~N
:~?B|_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr]\ru]r]`sUasedsmatEhtMjtektMnuEouUru]ouuvu}xvUyu}|vu}wF@wM}wfDwnFxFGwnJxfKxvNx~KyVRy^TyvUy^XzVYzf\znY{F`{Nb{fc{Nf|Fg|Vj|^g|vn|~p}Vq|~t}vu~Fx~Nu
:~?B}_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgd_dD[jdkmdsoeKpdssekte{wfCtf[{fc}f{~fdAg\BglEgtBhLIhTKhlLhTOiLPi\SidPi|WjDYj\ZjCjd\_kL`k\ckd`k|glDil\jlDml|nmLqmTnmlumtwnLxmt{nl|n}?oD|o]CoeEo}FoeIp]JpmMpuJ_EQq]RqmUquRrMYrU[rm\rU_sM`s]cse`s}gtEit]jtEmt}nuMquUnumuuuwvMxuu{vm|v~?wE|w^CwfEw~Fwc?_FKxnLx~OyFLy^SyfUy~VyfYz^Zzn]zvZ{Na{Vc{nd{Vg|Nh|^k|fh|~o}Fq}^r}Fu}~v~Ny~Vv
:~?B~_C@_SA_cD_kA`CH`KJ`cK`KNaCOaSRa[OasVa{XbSYa{\bs]cC`cK]ccdckfdCgckjdckdsnd{keSre[tesue[xfSy_C|fs}gD@gK}gdDglFhDGglJhdKhtNh|KiTRi\TitUi\XjTYjd\jlYkD`kLbkdckLflDglTjl\gltnl|pmTql|tmtunDxnLund|nk?oE@oMBoeCoMFpEGpUJp]GpuNp}PqUQp}TquUrEXrMUre\rm^sE_rmbsecsufs}ctUjt]ltumt]puUquetumqvExvMzve{vM~wF?_FBwfCwvFw~CxVJx^LxvMx^PyVQyfTynQzFXzNZzf[zN^{F_{Vb{^_{vf{~h|Vi{~l|vm}Fp}Nm}ft}nv~Fw}nz~f{
:~?C?_C@_KB_cC_KF`CG`SJ`[G`sN`{PaSQ`{TasUbCXbKUbc\bk^cC_bkbccccsfc{cdSjd[ldsmd[peSqectekqfCxfKzfc{fK~gD?gTBg\?gtFg|HhTIg|LhtMiDPiLMidTilVjDWilZjd[jt^j|[kTbk\dktek\hlTildlllimDpmLrmdsmLvnDwnTzn\wnt~n}@oUAn}DouEpEHpMEpeLpmNqEOpmRqeSquVq}SrUZr]\ru]r]`sUasedsmatEhtMjtektMnuEouUru]ouuvu}xvUyu}|vu}wF@wM}wfDwnFxFGwnJxfKxvNx~KyVRy^TyvUy^XzVYzf\znY{F`{Nb{fc{Nf|Fg|Vj|^g|vn|~p}Vq|~t}vu~Fx~Nu~f|~n
HERE

  $want_sparse6s =~ s/\n$//;
  my @want_sparse6s = split /\n/, $want_sparse6s;
  foreach my $N (0 .. $#want_sparse6s) {
    my $graph = Graph::Maker->new('most_maximum_matchings_tree',
                                  undirected => 1,
                                  N => $N);
    ok (scalar($graph->vertices), $N);
    
    my $want_sparse6 = $want_sparse6s[$N];
    my $reader = Graph::Reader::Graph6->new;
    open my $fh, '<', \$want_sparse6 or die;
    my $want_graph = $reader->read_graph($fh);
    ok (scalar($want_graph->vertices), $N);
    
    ok (MyGraphs::Graph_is_isomorphic($graph, $want_graph), 1,
        "N=$N sparse6 data");
  }
}

#------------------------------------------------------------------------------
exit 0;

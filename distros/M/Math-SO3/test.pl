# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}
use Math::SO3;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$exit_code=0;



$rotation=Math::SO3->new('zr' => 0.15,
                         'xd' => 30,
                         'z'  => 1);

$rotation->turn();

if($rotation->format_matrix() eq 
'[[   0.42533    0.80129    0.42074] [  -0.90195    0.33691    0.27015] [   0.07472   -0.49439    0.86603]]')
{
 print "ok 2\n";
}
else
{
 print "not ok 2\n";
 $exit_code=1;
}

$rotation->turn("yd" => 30, "zd" => -190);

$rotation2=$rotation->new();

$rotation->turn_round_axis((pack "d3", 10, 2, -4), 30, "degrees");
$rotation2->turn_round_axis((pack "d3", 5, 1, -2), 30, 'd');

$r1=$rotation->format_eigenvector();
$r2=$rotation2->format_eigenvector();

if($r1 eq $r2 and $r1 eq 
'<rotate  130.22193 deg round [  -0.02872    0.34843   -0.93689]>'
)
{
 print "ok 3\n";
}
else
{
 print "not ok 3\n";
# print $r1,"\n\n"; # DDD
 $exit_code=1;
}

$rotation2->turn('x' => 30, 'z' => -40);

$rotation->combine($rotation2);

if($rotation->format_euler_yxz() eq 
'<D_z(heading=  29.39018 deg) D_x(pitch=  61.72470 deg) D_y(roll= 242.89528 deg)>'
)
{
 print "ok 4\n";
}
else
{
 print "not ok 4\n";

# print $rotation->format_euler_yxz(),"\n\n"; # DDD
 $exit_code=1;
}

($angle, $dir)=$rotation->turning_angle_and_dir();

if($rotation->format_eigenvector() eq 
'<rotate  114.05842 deg round [   0.53000   -0.76342   -0.36916]>'
)
{
 print "ok 5\n";
}
else
{
 print "not ok 5\n";
 print $rotation->format_eigenvector(),"\n\n"; # DDD
 $exit_code=1;
}

$cos_angle=cos($angle);

@v_ortho0=(0.76342, 0.53000, 0);
$norm_v_ortho0=sqrt($v_ortho0[0]*$v_ortho0[0]+$v_ortho0[1]*$v_ortho0[1]+$v_ortho0[2]*$v_ortho0[2]);
$v_ortho=pack "d3", @v_ortho0;

$inv_rotation=$rotation->new();
$inv_rotation->invert();
$inv_rotation->translate_vectors($v_ortho);

@v_ortho1=unpack "d3", $v_ortho;

$cos_turn_angle=($v_ortho0[0]*$v_ortho1[0]+$v_ortho0[1]*$v_ortho1[1]+$v_ortho0[2]*$v_ortho1[2])/($norm_v_ortho0*$norm_v_ortho0);

if(abs($cos_angle-$cos_turn_angle)>0.001)
{
 print "not ok 6\n";
 $exit_code=1;
}
else
{
 print "ok 6\n";
}

@vec0_raw=([5,-8,3,1],[3,3,1,1],[2,4,5,1],[0,0,0,1],[4,1,2,0]);
@vec0_t=map {pack "d4", @$_} @vec0_raw;
$rotation->translate_vectors(@vec0_t);
@vec0_t_raw=map {[unpack "d4", $_]} @vec0_t;

$str=join '',(map {sprintf "[%10.5f %10.5f %10.5f %10.5f]", (unpack "d4",$_)}
             @vec0_t);

if($str eq
'[   8.45710   -1.82226   -4.81216    1.00000][  -2.33504    1.42148   -3.39514    1.00000][  -1.54272    5.58942   -3.37318    1.00000][   0.00000    0.00000   -0.00000    1.00000][  -0.11228    1.24421   -4.40901    0.00000]')
{
 print "ok 7\n";
}
else
{
 print "not ok 7\n";
 print $str;
 $exit_code=1;
}

$all_ok=1;

for($i=0;$i<=$#vec0_raw;$i++)
{
 $v0=$vec0_raw[$i];
 $vt=$vec0_t_raw[$i];

 $norm0=sqrt($v0->[0]*$v0->[0]+$v0->[1]*$v0->[1]+$v0->[2]*$v0->[2]);
 $norm_t=sqrt($vt->[0]*$vt->[0]+$vt->[1]*$vt->[1]+$vt->[2]*$vt->[2]);


 if(abs($norm0-$norm_t)>0.0001)
 {
  $all_ok=0;
 }
}

if($all_ok)
{
 print "ok 8\n";
}
else
{
 print "not ok 8\n";
 $exit_code=1;
}

$r=Math::SO3->new();

$ax=pack "d3", 0,1,0;

for($i=1;$i<1000;$i++)
{
 $r->turn('xd' => $i*3, 'yd' => $i*5, 'zd' => $i*-7);
 $r->turn_round_axis($ax, $i*0.5);
}

if(is_orthonormal($r))
{
 print "ok 9\n";
}
else
{
 print "not ok 9\n";
 $exit_code=1;
}

($angle, $axis)=$r->turning_angle_and_dir();

$r->turn_round_axis($axis, -$angle);

($phi, $theta, $psi)=$r->euler_angles_zxz('d');

$phi=$phi-360 if $phi>300;
$psi=$psi-360 if $psi>300;

if($phi*$phi+$theta*$theta+$psi*$psi<0.001)
  {
    print "ok 10\n";
  }
else
{
 print "not ok 10\n";
 $exit_code=1;
}

exit($exit_code);


# ==========

sub is_orthonormal
{
 my($mx)=@_;
 my(@elems, @onp);
 
 @elems=unpack "d9", $$mx;

 $onp[0]=$elems[0]*$elems[0]+$elems[1]*$elems[1]+$elems[2]*$elems[2];
 $onp[1]=$elems[3]*$elems[3]+$elems[4]*$elems[4]+$elems[5]*$elems[5];
 $onp[2]=$elems[6]*$elems[6]+$elems[7]*$elems[7]+$elems[8]*$elems[8];

 $onp[3]=$elems[0]*$elems[3]+$elems[1]*$elems[4]+$elems[2]*$elems[5];
 $onp[4]=$elems[0]*$elems[6]+$elems[1]*$elems[7]+$elems[2]*$elems[8];
 $onp[5]=$elems[3]*$elems[6]+$elems[4]*$elems[7]+$elems[5]*$elems[8];

 $deviation=( ($onp[0]-1)*($onp[0]-1)
             +($onp[1]-1)*($onp[1]-1)
             +($onp[2]-1)*($onp[2]-1)
             +$onp_[3]*$onp[3]+
             +$onp_[4]*$onp[4]+
             +$onp_[5]*$onp[5]);
 return ($deviation>0.001)?0:1;
}

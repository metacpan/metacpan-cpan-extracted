use strict;
use lib './lib';
use LEOCHARRE::DBI;
use Cwd;



sub _get_new_handle {
   my $abs = shift;
   $abs ||= _abs_db();

   my $dbh = DBI::connect_sqlite($abs);
   $dbh or die('cant open db connection, still open?');
   print STDERR "\n\n ++ OPENED SQLITE $abs\n\n";
   return $dbh;


}

sub _abs_db {
   cwd().'/t/test.db';
}




sub _gen_random_girl_hash {

   my $att ={};

   my @b = qw(A B C D DD);
   my @xtra = qw(offenses sins rings houses);
   my @ln = qw(Higgins Motlovina Rudnichek Ricardo Maldonado Potovac Gutierrez Gimenez Doubenande Smith Rogers DeMurnier);
   my @fn = qw(Elizabeth Susan Liz Effie Mina Maria Steph Lisa Indira Maggie Lana Saphira Quiana Laetitia Andrea Angela Laura Diana Jenna Lauren Juanita Beatriz Svetlana Maria Madeline Jessica Amanda Valeria Natalia Cristina);
   my @hair = qw(blonde brunette redhead);
   my @eyes =qw(green blue gray hazel brown black);
   my @mn = qw(Sue Jane Anne Nora Doris Lynn Brooke);
  
      $att = {       
         chest => (28 + (int rand 8)),
         cup => _randa(\@b),
         fname => _randa(\@fn),
         lname =>  _randa(\@ln),
         age => ((int rand 17) + 11), 
         weight => ((int rand 50 ) + 90),
         waist => int (19 + rand 12),
         hips =>  (30 + (int rand 10)),
         hair => _randa(\@hair),
         eyes => _randa(\@eyes),      
         height => _rand_height(),      
      };
   
   $att->{bust} = $att->{chest}.$att->{cup};

   my @n;
   if( int rand 2 ){
      $att->{mname} = _randa(\@mn);
   }
   
   for(qw(fname mname lname)){
      $att->{$_} or next;
      push @n, $att->{$_};
   }

   $att->{name} = join(' ',@n);
   
   $att->{_randa(\@xtra)} = int rand 200;

   return $att;


   

   sub _randa{
      my $a = shift;
      return $a->[(int rand scalar @$a)];
   }

   sub _rand_height {
      my $f = 5;
      my $i = int rand 18;
      if ($i>11){      
         $i = $i - 12;
         $f++;      
      }
      return "$f'$i\"";
   }
}







sub _gen_people_metadata {
   my $count_ = shift;
   $count_||=800;

   require Metadata::DB;
   my $dbh = _get_new_handle() or confess('cant get dbh handle');
	
   $dbh->{AutoCommit} = 0;

   my $_testop = 10;



   my $ran=0;
   my $id = 1;
   while ( $id++ < $count_){ 
      my $m = Metadata::DB->new({ DBH=>$dbh });

      unless($ran){
         $m->table_metadata_check;
         $ran=1;
      }

      $m->id($id);     
      my $att = _gen_random_girl_hash();
   

      my $count_added = scalar keys %$att;   
      
      $m->add(%$att);

=for
      if($id < $_testop){

         my @elements = $m->elements;

      
         my $count_elements = scalar @elements;
         my $count_elements_in_obj = $m->elements_count;

         ok( $count_elements == $count_elements_in_obj,'element count in obj ok');
 
   
         ok( $count_added == $count_elements, 
            "elements added [$count_added] == elements now[$count_elements]")
         or die;

          ### @elements 
       }
=cut
      

      $m->save;   
      #$m->dbh->commit;
   }
   
   $dbh->commit;
   $dbh->disconnect;
   
   printf STDERR " SAVED %s\n", _abs_db() ;
   return 1;
   
}











1;

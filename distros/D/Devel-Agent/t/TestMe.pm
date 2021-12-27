 package 
   TestMe;
  use Modern::Perl;
  use Moo;

  has test1=>(
    is=>'rw',
  );
  sub test_a {
    &main::test_a(123);
  }

  sub fatal {
    die;
  }

  sub jump {
    BLOCK_A: {
      goto BLOCK_B;
    }

    BLOCK_B: {
      return 1;
    }
  }

  sub jump_method {
    goto &target_method
    
  }

  sub target_method {
    return [@_];
  }
  sub DEMOLISH {} 
1;

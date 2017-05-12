************************************************************************
*
*    Test program for qr_alg_solver.
*
************************************************************************
      program test_qr_alg_solver
      implicit none
      double precision macheps
*>>>
*=================
* For IEEE single precision
*     parameter(macheps=1.19d-7)
* For IEEE double precision
      parameter(macheps=2.22d-16)
*=================
*>>>
      integer nx 
      parameter(nx=50)
      double precision c(0:nx-1)
      double precision zr(nx),zi(nx)
      double precision detil
      double precision a(nx*nx)
      integer cnt(nx)
      double precision wk((nx+1)*2)
*
      integer n
      integer rtn_code
      integer k
Comment:
*     macheps : machine epsion of the hardware floating number.
*     nx      : max degree of the polynomial. 10 or 500 or any.
*     c       : c(i) is the i-th degree's coefficients except principal term.
*     zr,zi   : Real and imaginary part of the roots solved.
*     detil   : Delta-Epsilon-Tilda; the accuracy hint.
*     a       : for work matrix area of order n.
*     cnt     : work are to count the QR-iteration.
*     wk      : work are to calculate the value of the polynomial for roots.
*
*     n       : The actual degree of the monic-polynomial.
*     rtn_code: return code from qr process.
*     k       : local loop index.
*End comment:
*
* Read the polynomial.
      print *, '(?) input degree of polynomial'
      read *, n
      if(.not.(n.le.nx)) then
        print *, 'Assert  (n <= nx) failed.'
        stop 
      endif
      print *, 'c(0)+c(1)*z+c(2)*z^2+...c(k)*z^k+...+z^n = 0.'
      print *, '(?) input c(0) ... c(n-1).'
      do k=0,n-1
        read *, c(k)
      enddo
      do k=0,n-1
        print *,'coef(',k,'):', c(k)
      enddo
*
* Compute the roots of the monic-polynomial by the QR-method.
      call qr_algeq_solver(n,c,macheps, zr,zi,detil, a,cnt,rtn_code)
      if(rtn_code.ne.0)then
        stop
      endif
*
* Print calculated roots.
      print *
      print 200,(k,zr(k),zi(k),k=1,n)
  200 format(1x,'ROOT',i5,'=(',1x,1pd22.15,',',1x,1pd22.15,')')
      print *
*
* Make report of the obtained result.
      call report(n,c,zr,zi,wk)
*
      end
************************************************************************
*
*     report the result of the calculation.
*
************************************************************************
      subroutine report(n,c,zr,zi,wk)
      implicit none
      integer n
      double precision c(0:n)
      double precision zr(n),zi(n)
      double precision wk(0:n,2)
*
      integer i
      double precision erra(2),errr(2)
      double precision relerr
* print calculated roots. and misc.
      print 400
      print 800
      do i=1,n
        call eval_monic_pol(n,c,zr(i),zi(i),erra,errr,wk)
        relerr=max(abs(errr(1)),abs(errr(2)))
        print 600, i,zr(i),zi(i),erra(1),erra(2),relerr
      enddo
      print 800
      return
*
  400 format
     &(//,10x,'calculated roots     :',4x,'val of pol:',
     & 1x,'rel error in val of pol')
  600 format('|',i2,':(',1pe22.15,',',1pe22.15,'):',
     &  '(',1pe8.1,',',1pe8.1,'):',1pe7.1,'|')
  800 format(1h+,78(1h-),1h+)
*
      end
************************************************************************
*
*  Evaluate the monic polynomial at its approximated root.
*  Values are in both absolute and relative.
*
************************************************************************
      subroutine eval_monic_pol(n,c,zr,zi,ea,er,wk)
      implicit none
      integer n
      double precision c(0:n-1)
      double precision zr,zi
      double precision ea(2)
      double precision er(2)
      double precision wk(0:n,2)
Comment
*     c     : real coefficients of the monic polynomial.
*     zr,zi : real and imaginary part of the (approximated) roots.
*     ea    : Error of the root 
*               measured by the value of polynomial.
*               ea(1) for real-part, ea(2) for imagnary part.
*     er    : Error of the roots 
*               measured by the relative value of polynomial.
*               er(1) for real-part, er(2) for imagnary part.
*     wk    : work area to store the terms.
*end comment;
      integer k
      double precision xk,yk,tmp
      double precision ermx
Comment:
* without using the horner method, calculate the values
* of terms of polynomial. xk,yk represents the real/imag
* part of the powers of the root.
      xk=1.d0
      yk=0.d0
      do k=0,n-1
        wk(k,1)=c(k)*xk
        wk(k,2)=c(k)*yk
        tmp=xk*zr-yk*zi
        yk=yk*zr+xk*zi
        xk=tmp
      enddo
      wk(n,1)=xk
      wk(n,2)=yk
Comment:
* sort real and imaginal parts of terms of polynomial
* separately into their increasing order in absolute values.
      call quick_sort_double(n+1,wk(0,1))
      call quick_sort_double(n+1,wk(0,2))
Comment: Add the terms from smaller to larger in magnitudes.
      ea(1)=0.d0
      ea(2)=0.d0
      do k=0,n
        ea(1)=ea(1)+wk(k,1)
        ea(2)=ea(2)+wk(k,2)
      enddo
Comment:
* Find out the largest term in absolute values
* seperately for real and imaginary parts.
* and let ermx the largest one.
      er(1)=0.d0
      er(2)=0.d0
      do k=0,n
        er(1)=max(er(1),abs(wk(k,1)))
        er(2)=max(er(2),abs(wk(k,2)))
      enddo
      ermx=max(er(1),er(2))
Comment:
* The relative error in evaluated value 
* of the polynomial is computed.
      if(ermx.eq.0.d0)then
        er(1)=0.d0
        er(2)=0.d0
      else
        er(1)=ea(1)/ermx
        er(2)=ea(2)/ermx
      endif
*
      end
************************************************************************
*
*      Sort an array of double in increased order of "absolute values".
*      By Hoare's Quick sort.
*
************************************************************************
      subroutine quick_sort_double(len,a)
      implicit none
*
      integer len
      double precision a(len)
*
      integer sp
      integer p,q,mid
      integer i,j
      double precision x,w
      integer mxstk
      parameter(mxstk=32)
      integer sp,stk(2,mxstk)
****** 
      sp=0
      sp=sp+1
      stk(1,sp)=1
      stk(2,sp)=len
    1 continue
      p=stk(1,sp)
      q=stk(2,sp)
      sp=sp-1
    2 continue
      i=p
      j=q
      mid=(p+q)/2
      x=abs(a(mid))
*Repeat
   10 if(abs(a(i)).lt.x)then
        i=i+1
        go to 10
      endif
   20 if(x.lt.abs(a(j)))then
        j=j-1
        go to 20
      endif
      if(i.le.j)then
        w=a(i)
        a(i)=a(j)
        a(j)=w
        i=i+1
        j=j-1
      endif
*Until i>j
      if(.not.(i.gt.j))go to 10
* process the longer interval later.
      if(j-p.lt.q-i)then
*case [i,q] is longer than [p,j]; 
* sort shorter interval [p,j] first and [i,q] later.
        if(i.lt.q)then
          sp=sp+1
          stk(1,sp)=i
          stk(2,sp)=q
        endif
        if(p.lt.j) then
          sp=sp+1
          stk(1,sp)=p
          stk(2,sp)=j
        endif
      else
*case [p,j] is longer than or equal [i,q];
* sort shorter interval [i,q] first and [p,j] later.
        if(p.lt.j)then
          sp=sp+1
          stk(1,sp)=p
          stk(2,sp)=j
        endif
        if(i.lt.q) then
          sp=sp+1
          stk(1,sp)=i
          stk(2,sp)=q
        endif
      endif
      if(sp.gt.0)go to 1
      end

************************************************************************
*
*  Solve the real coefficient monic algebraic equation by the QR-method.
*
************************************************************************
      subroutine qr_algeq_solver(n,c,macheps,
     &                 zr,zi,detil,
     &                 a,cnt,rtn_code)
      implicit none
      integer n
      double precision c(0:n-1)
      double precision macheps
*
      double precision zr(n),zi(n)
      double precision detil
      double precision a(n,n)
      integer cnt(n)
      integer rtn_code
Comments:
*     n       : degree of the monic polynomial.
*     c       : non-principal coefficients of the polynomial.
*               i-th degree coefficients is stored in c(i).
*     macheps : double precision machine epsilon.
*     zr,zi   : Re and Im part of output roots.
*     detil   : The accuracy hint.
*     a       : work matrix.
*     cnt     : work area for counting the qr-iterations.
*     rtn_code: return code from hqr_eigen_hessenberg.
*end comments;
*================
      integer i
      integer iter
      double precision afnorm
*
      if(n.le.0)then
        print *, 'qr_alg_solver: wrong arguments. (n<=0)'
        rtn_code=3
        return
      endif
*
* Build the companion matrix A.
      call build_companion(n,a,c)
*
* Balancing the A itself.
      call balance_companion(n,a)
*
* Compute the Frobenius norm of the balanced companion matrix A.
      call frobenius_norm_companion(n,a,afnorm)
*
* QR iterations from A.
      call hqr_eigen_hessenberg(n,a,macheps,  zr,zi,cnt,rtn_code)
      if(rtn_code.ne.0)then
        print*, 'in calling hqr_eigen_hessenberg abnormal condition'
        print*, 'rtn_code=',rtn_code
        if(rtn_code.eq.1) print *, 'matrix is completely zero.'
        if(rtn_code.eq.2) print *, 'QR iteration does not converged.'
        if(rtn_code.gt.3) print *, 'arguments violate the condition.'
        return
      endif
*
* Count the total QR iteration.
      iter=0
      do i=1,n
        if(cnt(i).gt.0)iter=iter+cnt(i)
      enddo 
      print *, 'iteration ',iter,' times.'
*
* Calculate the accuracy hint.
      detil=macheps*n*iter*afnorm
      print 600, 'O(del-e-tilda)=',detil
  600 format(1x,a,1pe8.2)
*
      end
************************************************************************
*
*  build the Companion Matrix of the polynomial.
*
************************************************************************
      subroutine build_companion(n,a,c)
      implicit none
      integer n
      double precision a(n,n)
      double precision c(0:n-1)
*
      integer i,j
*
      do j=1,n
        do i=1,n
          a(i,j)=0.d0
        enddo
      enddo
*
      do i=2,n
        a(i,i-1)=1.d0
      enddo
*
      do i=1,n
        a(i,n)=-c(i-1)
      enddo
*
      end
************************************************************************
*
*     Blancing the unsymmetric matrix A.
*
*  This fortran code is based on the Algol code "balance" from paper:
*   "Balancing a Matrixfor Calculation of Eigenvalues and Eigenvectors"
*   by B.N.Parlett and C.Reinsch, Numer. Math. 13, 293-304(1969).
*
*  Note: The only non-zero elements of the companion matrix are touched.
*
************************************************************************
      subroutine balance_companion(n,a)
      implicit none
      integer n
      double precision a(n,n)
      integer b
*>>>
*     parameter(b=16)
      parameter(b=2)
*>>>
Comment b is the base of the floating point representation on the machine.
*       It is 16 for base 16 float : for example, IBM system 360/370.
*       It is 2  for base  2 float : for example, IEEE float.
*End comment;
*
      integer b2
      parameter(b2=b**2)
      integer i,j
      double precision c,f,g,r,s
      logical noconv

* If n<=1, then do nothing.
      if(n.le.1)then
        return
      endif
* iteration:
    1 continue
        noconv=.false.
        do 100 i=1,n
C Generic code.
C         c=0.d0
C         r=0.d0
C         do j=1,i-1
C           c=c+abs(a(j,i))
C           r=r+abs(a(i,j))
C         enddo
C         do j=i+1,n
C           c=c+abs(a(j,i))
C           r=r+abs(a(i,j))
C         enddo
C begin specific code. Touch only non-zero elements of companion.
          if(i.ne.n)then
            c=abs(a(i+1,i))
          else
            c=0.d0
            do j=1,n-1
              c=c+abs(a(j,n))
            enddo
          endif
          if(i.eq.1)then
            r=abs(a(1,n))
          elseif(i.ne.n)then
            r=abs(a(i,i-1))+abs(a(i,n))
          else
            r=abs(a(i,i-1))
          endif
C end specific code.
*
          if(c.eq.0.d0.or.r.eq.0.d0) goto 100
*
          g=r/b
          f=1.d0
          s=c+r
*label L3:
    3     if(c.lt.g)then
            f=f*b
            c=c*b2
            goto 3
          endif
          g=r*b
*label L4:
    4     if(c.ge.g)then
            f=f/b
            c=c/b2
            goto 4
          endif
*Comment the preceding four lines may be replaced by a machine language
*        procedure computing the exponent sig such that 
*        sqrt(r/(c*b))<=b**sig<sqrt(r*b/c). Now balance;
          if((c+r)/f .lt. 0.95*s) then
            g=1.d0/f
            noconv=.true.
C Generic code.
C           do j=1,n
C             a(i,j)=a(i,j)*g
C           enddo
C           do j=1,n
C             a(j,i)=a(j,i)*f
C           enddo
C begin specific code. Touch only non-zero elements of companion.
            if(i.eq.1)then
              a(1,n)=a(1,n)*g
            else
              a(i,i-1)=a(i,i-1)*g
              a(i,n)=a(i,n)*g
            endif
            if(i.ne.n)then
              a(i+1,i)=a(i+1,i)*f
            else
              do j=1,n
                a(j,i)=a(j,i)*f
              enddo
            endif
C end specific code.
          endif
* Comment: 
*     the j joops may be done by exponent modification
*     in machine Language;
  100   enddo
      if(noconv) goto 1
      end
************************************************************************
*
*  Calculate the Frobenius norm of the companion-like matrix.
*  Note: The only non-zero elements of the companion matrix are touched.
*
************************************************************************
      subroutine frobenius_norm_companion(n,a,afnorm)
      implicit none
      integer n
      double precision a(n,n)
      double precision afnorm
*
      integer i,j
      double precision sum
*
C     sum=0.d0
C     do j=1,n
C       do i=1,n
C         sum=sum+a(i,j)**2
C       enddo
C     enddo
*
      sum=0.d0
      do j=1,n-1
        sum=sum+a(j+1,j)**2
      enddo
      do i=1,n
        sum=sum+a(i,n)**2
      enddo
*
      afnorm=sqrt(sum)
      end
************************************************************************
*
*     Eigenvalue Computation by the Householder QR method 
*     for the Real Hessenberg matrix.
* This fortran code is based on the Algol code "hqr" from the paper:
*       "The QR Algorithm for Real Hessenberg Matrices"
*       by R.S.Martin, G.Peters and J.H.Wilkinson,
*       Numer. Math. 14, 219-231(1970).
*
************************************************************************
      subroutine hqr_eigen_hessenberg(n0,h,macheps,  wr,wi,cnt,rtn_code)
      implicit none
*Comment: Finds the eigenvalues of a real upper Hessenberg matrix,
*         H, stored in the array h(1:n0,1:n0), and stores the real
*         parts in the array wr(1:n0) and the imaginary parts in the
*         array wi(1:n0). macheps is the relative machine precision.
*         The procedure fails if any eigenvalue takes more than 
*         30 iterations.
*
      integer n0
      double precision h(n0,n0)
      double precision macheps
*
      double precision wr(n0),wi(n0)
      integer cnt(n0)
      integer rtn_code
*===
      integer i,j,k,l,m,na,its
      double precision p,q,r,s,t,w,x,y,z
      logical notlast
      integer n
*===
* Note: n is changing in this subroutine.
      n=n0
*
      rtn_code=0
      t=0.d0
*label nextw:
    1 continue
      if(n.eq.0)goto 9
      its=0
      na=n-1
*Comment: look for single small sub-diagonal element;
*label nextit:
    2 continue
      do l=n,2,-1
       if(abs(h(l,l-1)).le.macheps*(abs(h(l-1,l-1))+abs(h(l,l))))then
         go to 3
       endif
      enddo
      l=1
*label cont1:
    3 continue
      x=h(n,n)
      if(l.eq.n)goto 6
      y=h(na,na)
      w=h(n,na)*h(na,n)
      if(l.eq.na)goto 7
      if(its.eq.30)then
        rtn_code=1
        return
      endif
      if(its.eq.10.or.its.eq.20)then
* Comment: form exceptional shift;
        t=t+x
        do i=1,n
          h(i,i)=h(i,i)-x
        enddo
        s=abs(h(n,na))+abs(h(na,n-2))
        y=0.75*s
        x=y
        w=-0.4375*s**2
      endif
      its=its+1
* Comment: look for two consecutive small sub-diagonal 
*          elements;
      do m=n-2,l,-1
        z=h(m,m)
        r=x-z
        s=y-z
        p=(r*s-w)/h(m+1,m)+h(m,m+1)
        q=h(m+1,m+1)-z-r-s
        r=h(m+2,m+1)
        s=abs(p)+abs(q)+abs(r)
        p=p/s
        q=q/s
        r=r/s
        if(m.eq.l)goto 4
        if(abs(h(m,m-1))*(abs(q)+abs(r)).le.macheps*abs(p)*
     &    (abs(h(m-1,m-1))+abs(z)+abs(h(m+1,m+1))))goto 4
      enddo
*label cont2:
    4 continue
      do i=m+2,n 
        h(i,i-2)=0.d0
      enddo
      do i=m+3,n
        h(i,i-3)=0.d0
      enddo
* Comment: double QR step involving rows l to n and columns m to n;
      do 100 k=m,na
        notlast=(k.ne.na)
        if(k.ne.m)then
          p=h(k,k-1)
          q=h(k+1,k-1)
          if(notlast)then
            r=h(k+2,k-1)
          else
            r=0.d0
          endif
          x=abs(p)+abs(q)+abs(r)
          if(x.eq.0.d0)goto 5
          p=p/x
          q=q/x
          r=r/x
        endif
        s=sqrt(p**2+q**2+r**2)
        if(p.lt.0.d0)s=-s
        if(k.ne.m)then
          h(k,k-1)=-s*x
        elseif(l.ne.m)then
          h(k,k-1)=-h(k,k-1) 
        endif
        p=p+s
        x=p/s
        y=q/s
        z=r/s
        q=q/p
        r=r/p
* Comment: row modification;
        do j=k,n
          p=h(k,j)+q*h(k+1,j)
          if(notlast)then
            p=p+r*h(k+2,j)
            h(k+2,j)=h(k+2,j)-p*z
          endif
          h(k+1,j)=h(k+1,j)-p*y
          h(k,j)=h(k,j)-p*x
        enddo
        if(k+3.lt.n)then
          j=k+3
        else
          j=n
        endif
* Comment: column modification;
        do i=l,j
          p=x*h(i,k)+y*h(i,k+1)
          if(notlast)then
            p=p+z*h(i,k+2)
            h(i,k+2)=h(i,k+2)-p*r
          endif
          h(i,k+1)=h(i,k+1)-p*q
          h(i,k)=h(i,k)-p
        enddo
*label cont3:
    5   continue
  100 enddo
      goto 2
* Comment: one root found;
*label onew:
    6 continue
      wr(n)=x+t
      wi(n)=0.d0
      cnt(n)=its
      n=na
      goto 1
* Comment: two roots found;
*label twow:
    7 continue
      p=(y-x)/2
      q=p**2+w
      y=sqrt(abs(q))
      cnt(n)=-its
      cnt(na)=its
      x=x+t
      if(q.gt.0.d0)then
*Comment: real pair;
        if(p.lt.0.d0)y=-y
        y=p+y
        wr(na)=x+y
        wr(n)=x-w/y
        wi(na)=0.d0
        wi(n)=0.d0
      else
*Comment: complex pair;
        wr(na)=x+p
        wr(n)=x+p
        wi(na)=y
        wi(n)=-y
      endif
      n=n-2
      goto 1
*label fin:
    9 continue
      end

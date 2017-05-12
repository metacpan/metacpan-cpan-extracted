C**** SRLOCAT.FOR    Insolation at specified LOCATion    2004/10/12
C****
      IMPLICIT REAL*8 (A-H,O-Z)
      PARAMETER (TWOPI=6.283185307179586477d0, EDAYzY=365.2425d0,
     *           RSUNd =.267d0,  !  mean radius of Sun in degrees
     *           REFRAC=.583d0)  !  effective Sun disk increase
      INTEGER*4 DAYzMO(12), DATMAX
      LOGICAL*4 QLEAPY
      CHARACTER ARG*80, CTZONE(-12:12)*33
C****
      DATA DAYzMO /31,28,31, 30,31,30, 31,31,30, 31,30,31/
      DATA CTZONE /'Yankee Standard Time',
     B             'Phoenix Island Standard Time',
     A             'Hawaiian Standard Time',
     9             'Alaska Standard Time',
     8             'Pacific Standard Time',
     7             'Mountain Standard Time',
     6             'Central Standard Time',
     5             'Eastern Standard Time',
     4             'Atlantic Standard Time',
     3             'Brazilian Standard Time',
     2             'Fernando de Noronha Standard Time',
     1             'Jan Mayen Standard Time',
     O             'Greenwich Mean Time',
     1             'Central Europe Time',
     2             'Eastern Europe Time',
     3             'Moscow Standard Time',
     4             'Afghan Standard Time',
     5             'Indian Standard Time',
     6             'Bangladesh Standard Time',
     7             'Vietnam Standard Time',
     8             'Australian Western Standard Time',
     9             'Japanese Standard Time',
     A             'Australian Eastern Standard Time',
     B             'New Caledonia Standard Time',
     C             'Fiji Standard Time'/
C****
      NARGS = IARGC()
      IF(NARGS.le.0)  GO TO 800
      RLAT =  40.78
      RLON = -73.97
      JYEAR = 2004
      MONMIN = 1
      MONMAX = 12
C****
C**** Read input from console
C****
C**** Determine latitude
      CALL GETARG (1,ARG)
      READ (ARG,*,ERR=810) RLAT
      IF(ABS(RLAT).gt.90.)  GO TO 811
      IF(NARGS.le.1)  GO TO 200
C**** Determine longitude
      CALL GETARG (2,ARG)
      READ (ARG,*,ERR=812) RLON
      IF(RLON.gt. 187.5)  RLON = RLON - 360.
      IF(RLON.lt.-187.5)  RLON = RLON + 360.
      IF(ABS(RLON).gt.187.5)  GO TO 813
      IF(NARGS.le.2)  GO TO 200
C**** Determine year
      CALL GETARG (3,ARG)
      READ (ARG,*,ERR=814) JYEAR
      IF(NARGS.le.3)  GO TO 200
C**** Determine month
      CALL GETARG (4,ARG)
      READ (ARG,*,ERR=816) MONTH
      IF(MONTH.lt.1 .or. MONTH.gt.12)  GO TO 817
      MONMIN = MONTH
      MONMAX = MONTH
C**** Determine time zone
  200 ITZONE = NINT(RLON/15.)
C**** Determine orbital parameters
      YEAR = JYEAR
      CALL ORBPAR (YEAR, ECCEN,OBLIQ,OMEGVP)
C**** Write header information to web page
      WRITE (6,930) RLAT,RLON,
     *      TRIM(CTZONE(ITZONE)), ITZONE*15.-7.5, ITZONE*15.+7.5
C**** Loop over months
      DO 700 MONTH=MONMIN,MONMAX
      IF(MONTH.gt.MONMIN)  WRITE (6,*)
C**** Loop over days
      DATMAX = DAYzMO(MONTH)
      IF(MONTH.eq.2 .and. QLEAPY(JYEAR))  DATMAX = 29
      DO 700 JDATE=1,DATMAX
C****
      DATE = JDATE-1 + .5 - RLON/360.d0
      CALL YMDtoD (JYEAR,MONTH,DATE,   DAY)
      CALL ORBIT  (ECCEN,OBLIQ,OMEGVP, DAY,
     *             DIST,SIND,COSD,SUNLON,SUNLAT,EQTIME)
      CALL COSZIJ (RLAT,SIND,COSD, COSZT,COSZS)

C			WRITE (6, *) "RLAT "
C			WRITE (6, *) RLAT
C			WRITE (6, *) "SIND "
C			WRITE (6, *) SIND
C			WRITE (6, *) "COSD "
C			WRITE (6, *) COSD
C			WRITE (6, *) "COSZT "
C			WRITE (6, *) COSZT
C			WRITE (6, *) "COSZS "
C			WRITE (6, *) COSZS

      RSmEzM = (REFRAC + RSUNd/DIST) * TWOPI/360.
      CALL SUNSET (RLAT,SIND,COSD,RSmEzM, DUSK)
      IF(DUSK.ge. 999999.)  GO TO 500
      IF(DUSK.le.-999999.)  GO TO 600
C****
C**** Daylight and nightime at this location on this day
C****
      DAWN   = (-DUSK-EQTIME)*24./TWOPI + 12. - RLON/15. + ITZONE
      DUSK   = ( DUSK-EQTIME)*24./TWOPI + 12. - RLON/15. + ITZONE

      IDAWNH = DAWN
      IDUSKH = DUSK

      IDAWNM = NINT((DAWN-IDAWNH)*60.)
      IDUSKM = NINT((DUSK-IDUSKH)*60.)

C		WRITE (6, *) "---->DAWN"
C		WRITE (6, *) DAWN
C		WRITE (6, *) IDAWNH
C		WRITE (6, *) DAWN-IDAWNH
C		WRITE (6, *) ((DAWN-IDAWNH) * 60.)
C		WRITE (6, *) IDAWNM
C		WRITE (6, *) "<----DAWN"

      SRINC  = 1367.*COSZT/DIST**2
      IF(JDATE.eq.1)  WRITE (6,941) JYEAR,MONTH,JDATE,
     *               IDAWNH,IDAWNM, IDUSKH,IDUSKM, SRINC,COSZS
      IF(JDATE.gt.1)  WRITE (6,942) JDATE,
     *               IDAWNH,IDAWNM, IDUSKH,IDUSKM, SRINC,COSZS
      GO TO 700
C****
C**** Daylight at all times at this location on this day
C****
  500 SRINC = 1367.*COSZT/DIST**2
      IF(JDATE.eq.1)  WRITE (6,951) JYEAR,MONTH,JDATE, SRINC,COSZS
      IF(JDATE.gt.1)  WRITE (6,952)             JDATE, SRINC,COSZS
      GO TO 700
C****
C**** Nightime at all times at this location on this day
C****
  600 SRINC = 1367.*COSZT/DIST**2
      IF(JDATE.eq.1)  WRITE (6,961) JYEAR,MONTH,JDATE, SRINC,COSZS
      IF(JDATE.gt.1)  WRITE (6,962)             JDATE, SRINC,COSZS
  700 continue
      GO TO 999
C****
  800 WRITE (6,*) 'Usage: SRLOCAT Lat [Lon Year Mon]          ' //
     *            '                2004/10/12'
      WRITE (6,*) '       Daily sunrise, sunset and insolation' //
     *            ' as a function of Location'
      GO TO 999
  810 WRITE (0,*) 'Unable to decipher latitude: ',TRIM(ARG)
      STOP 810
  811 WRITE (0,*) 'Specified latitude is out or range: ',RLAT
      STOP 811
  812 WRITE (0,*) 'Unable to decipher longitude: ',TRIM(ARG)
      STOP 812
  813 WRITE (0,*) 'Specified longitude is out or range: ',RLON
      STOP 813
  814 WRITE (0,*) 'Unable to decipher year: ',TRIM(ARG)
      STOP 814
  816 WRITE (0,*) 'Unable to decipher month: ',TRIM(ARG)
      STOP 816
  817 WRITE (0,*) 'Specified month is out or range: ',MONTH
      STOP 817
C****
  900 FORMAT ('Content-type: text/plain' /)
  930 FORMAT ('Daily Insolation Parameters' //
     *'Latitude:',F7.2,5X,'Longitude:',F7.2 /
     *'Time Zone: ',A,'  Longitudes',F7.1,'  to',F7.1,')' /
     *'Local Standard Time is used, not Daylight Time.' /
     *'For Daylight Time add 1 hour to times reported in table below.'//
     *'                                           Sunlight' /
     *'                                          Weighted' /
     *'                                 Daily     Cosine' /
     *'                                Average      of' /
     *'                                Sunlight   Zenith' /
     *'      Date   Sunrise   Sunset    (W/m²)    Angle' /
     *'      ----   -------   ------    ------    -----')
  941 FORMAT (I4,2('/',I2.2), 2(I6,':',I2.2), F11.2, F8.3)
  942 FORMAT (        I10.2 , 2(I6,':',I2.2), F11.2, F8.3)
  951 FORMAT (I4,2('/',I2.2),'   Always Day Light', F11.2, F8.3)
  952 FORMAT (        I10.2 ,'   Always Day Light', F11.2, F8.3)
  961 FORMAT (I4,2('/',I2.2),'   Always Nightime ', F11.2, F8.3)
  962 FORMAT (        I10.2 ,'   Always Nightime ', F11.2, F8.3)
  999 END

      SUBROUTINE ORBPAR (YEAR, ECCEN,OBLIQ,OMEGVP)
C****
C**** ORBPAR calculates the three orbital parameters as a function of
C**** YEAR.  The source of these calculations is: Andre L. Berger,
C**** 1978, "Long-Term Variations of Daily Insolation and Quaternary
C**** Climatic Changes", JAS, v.35, p.2362.  Also useful is: Andre L.
C**** Berger, May 1978, "A Simple Algorithm to Compute Long Term
C**** Variations of Daily Insolation", published by Institut
C**** D'Astronomie de Geophysique, Universite Catholique de Louvain,
C**** Louvain-la Neuve, No. 18.
C****
C**** Tables and equations refer to the first reference (JAS).  The
C**** corresponding table or equation in the second reference is
C**** enclosed in parentheses.  The coefficients used in this
C**** subroutine are slightly more precise than those used in either
C**** of the references.  The generated orbital parameters are precise
C**** within plus or minus 1000000 years from present.
C****
C**** Input:  YEAR   = years A.D. are positive, B.C. are negative
C**** Output: ECCEN  = eccentricity of orbital ellipse
C****         OBLIQ  = latitude of Tropic of Cancer in radians
C****         OMEGVP = longitude of perihelion =
C****                = spatial angle from vernal equinox to perihelion
C****                  in radians with sun as angle vertex
C****
      IMPLICIT REAL*8 (A-H,O-Z)
      PARAMETER (TWOPI=6.283185307179586477d0, PIz180=TWOPI/360.d0)
      REAL*8 TABLE1(3,47),TABLE4(3,19),TABLE5(3,78)
C**** Table 1 (2).  Obliquity relative to mean ecliptic of date: OBLIQD
      DATA TABLE1/-2462.2214466d0, 31.609974d0, 251.9025d0,
     2             -857.3232075d0, 32.620504d0, 280.8325d0,
     3             -629.3231835d0, 24.172203d0, 128.3057d0,
     4             -414.2804924d0, 31.983787d0, 292.7252d0,
     5             -311.7632587d0, 44.828336d0,  15.3747d0,
     6              308.9408604d0, 30.973257d0, 263.7951d0,
     7             -162.5533601d0, 43.668246d0, 308.4258d0,
     8             -116.1077911d0, 32.246691d0, 240.0099d0,
     9              101.1189923d0, 30.599444d0, 222.9725d0,
     O              -67.6856209d0, 42.681324d0, 268.7809d0,
     1               24.9079067d0, 43.836462d0, 316.7998d0,
     2               22.5811241d0, 47.439436d0, 319.6024d0,
     3              -21.1648355d0, 63.219948d0, 143.8050d0,
     4              -15.6549876d0, 64.230478d0, 172.7351d0,
     5               15.3936813d0,  1.010530d0,  28.9300d0,
     6               14.6660938d0,  7.437771d0, 123.5968d0,
     7              -11.7273029d0, 55.782177d0,  20.2082d0,
     8               10.2742696d0,   .373813d0,  40.8226d0,
     9                6.4914588d0, 13.218362d0, 123.4722d0,
     O                5.8539148d0, 62.583231d0, 155.6977d0,
     1               -5.4872205d0, 63.593761d0, 184.6277d0,
     2               -5.4290191d0, 76.438310d0, 267.2772d0,
     3                5.1609570d0, 45.815258d0,  55.0196d0,
     4                5.0786314d0,  8.448301d0, 152.5268d0,
     5               -4.0735782d0, 56.792707d0,  49.1382d0,
     6                3.7227167d0, 49.747842d0, 204.6609d0,
     7                3.3971932d0, 12.058272d0,  56.5233d0,
     8               -2.8347004d0, 75.278220d0, 200.3284d0,
     9               -2.6550721d0, 65.241008d0, 201.6651d0,
     O               -2.5717867d0, 64.604291d0, 213.5577d0,
     1               -2.4712188d0,  1.647247d0,  17.0374d0,
     2                2.4625410d0,  7.811584d0, 164.4194d0,
     3                2.2464112d0, 12.207832d0,  94.5422d0,
     4               -2.0755511d0, 63.856665d0, 131.9124d0,
     5               -1.9713669d0, 56.155990d0,  61.0309d0,
     6               -1.8813061d0, 77.448840d0, 296.2073d0,
     7               -1.8468785d0,  6.801054d0, 135.4894d0,
     8                1.8186742d0, 62.209418d0, 114.8750d0,
     9                1.7601888d0, 20.656133d0, 247.0691d0,
     O               -1.5428851d0, 48.344406d0, 256.6114d0,
     1                1.4738838d0, 55.145460d0,  32.1008d0,
     2               -1.4593669d0, 69.000539d0, 143.6804d0,
     3                1.4192259d0, 11.071350d0,  16.8784d0,
     4               -1.1818980d0, 74.291298d0, 160.6835d0,
     5                1.1756474d0, 11.047742d0,  27.5932d0,
     6               -1.1316126d0,  0.636717d0, 348.1074d0,
     7                1.0896928d0, 12.844549d0,  82.6496d0/
C**** Table 4 (1).  Fundamental elements of the ecliptic: ECCEN sin(pi)
      DATA TABLE4/ .01860798d0,  4.207205d0,  28.620089d0,
     2             .01627522d0,  7.346091d0, 193.788772d0,
     3            -.01300660d0, 17.857263d0, 308.307024d0,
     4             .00988829d0, 17.220546d0, 320.199637d0,
     5            -.00336700d0, 16.846733d0, 279.376984d0,
     6             .00333077d0,  5.199079d0,  87.195000d0,
     7            -.00235400d0, 18.231076d0, 349.129677d0,
     8             .00140015d0, 26.216758d0, 128.443387d0,
     9             .00100700d0,  6.359169d0, 154.143880d0,
     O             .00085700d0, 16.210016d0, 291.269597d0,
     1             .00064990d0,  3.065181d0, 114.860583d0,
     2             .00059900d0, 16.583829d0, 332.092251d0,
     3             .00037800d0, 18.493980d0, 296.414411d0,
     4            -.00033700d0,  6.190953d0, 145.769910d0,
     5             .00027600d0, 18.867793d0, 337.237063d0,
     6             .00018200d0, 17.425567d0, 152.092288d0,
     7            -.00017400d0,  6.186001d0, 126.839891d0,
     8            -.00012400d0, 18.417441d0, 210.667199d0,
     9             .00001250d0,  0.667863d0,  72.108838d0/
C**** Table 5 (3).  General precession in longitude: psi
      DATA TABLE5/ 7391.0225890d0, 31.609974d0, 251.9025d0,
     2             2555.1526947d0, 32.620504d0, 280.8325d0,
     3             2022.7629188d0, 24.172203d0, 128.3057d0,
     4            -1973.6517951d0,  0.636717d0, 348.1074d0,
     5             1240.2321818d0, 31.983787d0, 292.7252d0,
     6              953.8679112d0,  3.138886d0, 165.1686d0,
     7             -931.7537108d0, 30.973257d0, 263.7951d0,
     8              872.3795383d0, 44.828336d0,  15.3747d0,
     9              606.3544732d0,  0.991874d0,  58.5749d0,
     O             -496.0274038d0,  0.373813d0,  40.8226d0,
     1              456.9608039d0, 43.668246d0, 308.4258d0,
     2              346.9462320d0, 32.246691d0, 240.0099d0,
     3             -305.8412902d0, 30.599444d0, 222.9725d0,
     4              249.6173246d0,  2.147012d0, 106.5937d0,
     5             -199.1027200d0, 10.511172d0, 114.5182d0,
     6              191.0560889d0, 42.681324d0, 268.7809d0,
     7             -175.2936572d0, 13.650058d0, 279.6869d0,
     8              165.9068833d0,  0.986922d0,  39.6448d0,
     9              161.1285917d0,  9.874455d0, 126.4108d0,
     O              139.7878093d0, 13.013341d0, 291.5795d0,
     1             -133.5228399d0,  0.262904d0, 307.2848d0,
     2              117.0673811d0,  0.004952d0,  18.9300d0,
     3              104.6907281d0,  1.142024d0, 273.7596d0,
     4               95.3227476d0, 63.219948d0, 143.8050d0,
     5               86.7824524d0,  0.205021d0, 191.8927d0,
     6               86.0857729d0,  2.151964d0, 125.5237d0,
     7               70.5893698d0, 64.230478d0, 172.7351d0,
     8              -69.9719343d0, 43.836462d0, 316.7998d0,
     9              -62.5817473d0, 47.439436d0, 319.6024d0,
     O               61.5450059d0,  1.384343d0,  69.7526d0,
     1              -57.9364011d0,  7.437771d0, 123.5968d0,
     2               57.1899832d0, 18.829299d0, 217.6432d0,
     3              -57.0236109d0,  9.500642d0,  85.5882d0,
     4              -54.2119253d0,  0.431696d0, 156.2147d0,
     5               53.2834147d0,  1.160090d0,  66.9489d0,
     6               52.1223575d0, 55.782177d0,  20.2082d0,
     7              -49.0059908d0, 12.639528d0, 250.7568d0,
     8              -48.3118757d0,  1.155138d0,  48.0188d0,
     9              -45.4191685d0,  0.168216d0,   8.3739d0,
     O              -42.2357920d0,  1.647247d0,  17.0374d0,
     1              -34.7971099d0, 10.884985d0, 155.3409d0,
     2               34.4623613d0,  5.610937d0,  94.1709d0,
     3              -33.8356643d0, 12.658184d0, 221.1120d0,
     4               33.6689362d0,  1.010530d0,  28.9300d0,
     5              -31.2521586d0,  1.983748d0, 117.1498d0,
     6              -30.8798701d0, 14.023871d0, 320.5095d0,
     7               28.4640769d0,  0.560178d0, 262.3602d0,
     8              -27.1960802d0,  1.273434d0, 336.2148d0,
     9               27.0860736d0, 12.021467d0, 233.0046d0,
     O              -26.3437456d0, 62.583231d0, 155.6977d0,
     1               24.7253740d0, 63.593761d0, 184.6277d0,
     2               24.6732126d0, 76.438310d0, 267.2772d0,
     3               24.4272733d0,  4.280910d0,  78.9281d0,
     4               24.0127327d0, 13.218362d0, 123.4722d0,
     5               21.7150294d0, 17.818769d0, 188.7132d0,
     6              -21.5375347d0,  8.359495d0, 180.1364d0,
     7               18.1148363d0, 56.792707d0,  49.1382d0,
     8              -16.9603104d0,  8.448301d0, 152.5268d0,
     9              -16.1765215d0,  1.978796d0,  98.2198d0,
     O               15.5567653d0,  8.863925d0,  97.4808d0,
     1               15.4846529d0,  0.186365d0, 221.5376d0,
     2               15.2150632d0,  8.996212d0, 168.2438d0,
     3               14.5047426d0,  6.771027d0, 161.1199d0,
     4              -14.3873316d0, 45.815258d0,  55.0196d0,
     5               13.1351419d0, 12.002811d0, 262.6495d0,
     6               12.8776311d0, 75.278220d0, 200.3284d0,
     7               11.9867234d0, 65.241008d0, 201.6651d0,
     8               11.9385578d0, 18.870667d0, 294.6547d0,
     9               11.7030822d0, 22.009553d0,  99.8233d0,
     O               11.6018181d0, 64.604291d0, 213.5577d0,
     1              -11.2617293d0, 11.498094d0, 154.1631d0,
     2              -10.4664199d0,  0.578834d0, 232.7153d0,
     3               10.4333970d0,  9.237738d0, 138.3034d0,
     4              -10.2377466d0, 49.747842d0, 204.6609d0,
     5               10.1934446d0,  2.147012d0, 106.5938d0,
     6              -10.1280191d0,  1.196895d0, 250.4676d0,
     7               10.0289441d0,  2.133898d0, 332.3345d0,
     8              -10.0034259d0,  0.173168d0,  27.3039d0/
C****
      YM1950 = YEAR-1950.
C****
C**** Obliquity from Table 1 (2):
C****   OBLIQ# = 23.320556 (degrees)             Equation 5.5 (15)
C****   OBLIQD = OBLIQ# + sum[A cos(ft+delta)]   Equation 1 (5)
C****
      SUMC = 0.
      DO 110 I=1,47
      ARG    = PIz180*(YM1950*TABLE1(2,I)/3600.+TABLE1(3,I))
  110 SUMC   = SUMC + TABLE1(1,I)*COS(ARG)
      OBLIQD = 23.320556d0 + SUMC/3600.
      OBLIQ  = OBLIQD*PIz180
C****
C**** Eccentricity from Table 4 (1):
C****   ECCEN sin(pi) = sum[M sin(gt+beta)]           Equation 4 (1)
C****   ECCEN cos(pi) = sum[M cos(gt+beta)]           Equation 4 (1)
C****   ECCEN = ECCEN sqrt[sin(pi)^2 + cos(pi)^2]
C****
      ESINPI = 0.
      ECOSPI = 0.
      DO 210 I=1,19
      ARG    = PIz180*(YM1950*TABLE4(2,I)/3600.+TABLE4(3,I))
      ESINPI = ESINPI + TABLE4(1,I)*SIN(ARG)
  210 ECOSPI = ECOSPI + TABLE4(1,I)*COS(ARG)
      ECCEN  = SQRT(ESINPI*ESINPI+ECOSPI*ECOSPI)
C****
C**** Perihelion from Equation 4,6,7 (9) and Table 4,5 (1,3):
C****   PSI# = 50.439273 (seconds of degree)         Equation 7.5 (16)
C****   ZETA =  3.392506 (degrees)                   Equation 7.5 (17)
C****   PSI = PSI# t + ZETA + sum[F sin(ft+delta)]   Equation 7 (9)
C****   PIE = atan[ECCEN sin(pi) / ECCEN cos(pi)]
C****   OMEGVP = PIE + PSI + 3.14159                 Equation 6 (4.5)
C****
      PIE    = ATAN2(ESINPI,ECOSPI)
      FSINFD = 0.
      DO 310 I=1,78
      ARG    = PIz180*(YM1950*TABLE5(2,I)/3600.+TABLE5(3,I))
  310 FSINFD = FSINFD + TABLE5(1,I)*SIN(ARG)
      PSI    = PIz180*(3.392506d0+(YM1950*50.439273d0+FSINFD)/3600.)
      OMEGVP = MODULO (PIE+PSI+.5*TWOPI, TWOPI)
C****
      RETURN
      END

      SUBROUTINE COSZIJ (RLAT,SIND,COSD, COSZT,COSZS)
C****
C**** COSZIJ calculates the daily average cosine of the zenith angle
C**** weighted by time and weighted by sunlight.
C****
C**** Input: RLAT = latitude (degrees)
C****   SIND,COSD = sine and cosine of the declination angle
C****
C**** Output: COSZT = sum(cosZ*dT) / sum(dT)
C****         COSZS = sum(cosZ*cosZ*dT) / sum(cosZ*dT)
C****
C**** Intern: DAWN = time of DAWN (temporal radians) at mean local time
C****         DUSK = time of DUSK (temporal radians) at mean local time
C****
      IMPLICIT REAL*8 (A-H,O-Z)
      PARAMETER (TWOPI=6.283185307179586477d0)
C****
      SINJ = SIN(TWOPI*RLAT/360.)
      COSJ = COS(TWOPI*RLAT/360.)
      SJSD = SINJ*SIND
      CJCD = COSJ*COSD
      IF(SJSD+CJCD.le.0.)  GO TO 20
      IF(SJSD-CJCD.ge.0.)  GO TO 10
C**** Compute DAWN and DUSK (at local time) and their sines
      CDUSK = - SJSD/CJCD
      DUSK  = ACOS(CDUSK)
      SDUSK = SQRT(CJCD*CJCD-SJSD*SJSD) / CJCD
      S2DUSK= 2.*SDUSK*CDUSK
      DAWN  = - DUSK
      SDAWN = - SDUSK
      S2DAWN= - S2DUSK
C**** Nightime at initial and final times with daylight in between
      ECOSZ = SJSD*(DUSK-DAWN) + CJCD*(SDUSK-SDAWN)
      QCOSZ = SJSD*ECOSZ + CJCD*(SJSD*(SDUSK-SDAWN) +
     +        .5*CJCD*(DUSK-DAWN + .5*(S2DUSK-S2DAWN)))
      COSZT = ECOSZ/TWOPI
      COSZS = QCOSZ/ECOSZ
      RETURN
C**** Constant daylight at this latitude
   10 DAWN  = -999999.
      DUSK  = -999999.
      ECOSZ = SJSD*TWOPI
      QCOSZ = SJSD*ECOSZ + .5*CJCD*CJCD*TWOPI
      COSZT = SJSD  !  = ECOSZ/TWOPI
      COSZS = QCOSZ/ECOSZ
      RETURN
C**** Constant nightime at this latitude
   20 DAWN  = 999999.
      DUSK  = 999999.
      COSZT = 0.
      COSZS = 0.
      RETURN
      END

      SUBROUTINE SUNSET (RLAT,SIND,COSD,RSmEzM, DUSK)
C****
C**** Input: RLAT = latitude (degrees)
C****   SIND,COSD = sine and cosine of the declination angle
C****      RSmEzM = (Sun Radius - Earth Radius) / (distance to Sun)
C****
C**** Output: DUSK = time of DUSK (temporal radians) at mean local time
C****
      IMPLICIT REAL*8 (A-H,O-Z)
      PARAMETER (TWOPI=6.283185307179586477d0)
C****
      SINJ = SIN(TWOPI*RLAT/360.)
      COSJ = COS(TWOPI*RLAT/360.)
      SJSD = SINJ*SIND
      CJCD = COSJ*COSD
      IF(SJSD+RSmEzM+CJCD.le.0.)  GO TO 20
      IF(SJSD+RSmEzM-CJCD.ge.0.)  GO TO 10
C**** Compute DUSK (at local time)
      CDUSK = - (SJSD + RSmEzM) / CJCD  !  cosine of DUSK
      DUSK  = ACOS(CDUSK)
      RETURN
C**** Constant daylight at this latitude
   10 DUSK = 999999.
      RETURN
C**** Constant nightime at this latitude
   20 DUSK = -999999.
      RETURN
      END

      SUBROUTINE ORBIT (ECCEN,OBLIQ,OMEGVP, DAY,
     *                  DIST,SIND,COSD,SUNLON,SUNLAT,EQTIME)
C****
C**** ORBIT receives orbital parameters and time of year, and returns
C**** distance from Sun and Sun's position.
C**** Reference for following caculations is: V.M.Blanco and
C**** S.W.McCuskey, 1961, "Basic Physics of the Solar System", pages
C**** 135 - 151.  Existence of Moon and heavenly bodies other than
C**** Earth and Sun are ignored.  Earth is assumed to be spherical.
C****
C**** Program author: Gary L. Russell 2002/09/25
C**** Angles, longitude and latitude are measured in radians.
C****
C**** Input: ECCEN  = eccentricity of the orbital ellipse
C****        OBLIQ  = latitude of Tropic of Cancer
C****        OMEGVP = longitude of perihelion (sometimes Pi is added) =
C****               = spatial angle from vernal equinox to perihelion
C****                 with Sun as angle vertex
C****        DAY    = days measured since 2000 January 1, hour 0
C****
C**** Constants: EDAYzY = tropical year = Earth days per year = 365.2425
C****            VE200D = days from 2000 January 1, hour 0 till vernal
C****                     equinox of year 2000 = 31 + 29 + 19 + 7.5/24
C****
C**** Intermediate quantities:
C****    BSEMI = semi minor axis in units of semi major axis
C****   PERIHE = perihelion in days since 2000 January 1, hour 0
C****            in its annual revolution about Sun
C****       TA = true anomaly = spatial angle from perihelion to
C****            current location with Sun as angle vertex
C****       EA = eccentric anomaly = spatial angle measured along
C****            eccentric circle (that circumscribes Earth's orbit)
C****            from perihelion to point above (or below) Earth's
C****            absisca (where absisca is directed from center of
C****            eccentric circle to perihelion)
C****       MA = mean anomaly = temporal angle from perihelion to
C****            current time in units of 2*Pi per tropical year
C****   TAofVE = TA(VE) = true anomaly of vernal equinox = - OMEGVP
C****   EAofVE = EA(VE) = eccentric anomaly of vernal equinox
C****   MAofVE = MA(VE) = mean anomaly of vernal equinox
C****   SLNORO = longitude of Sun in Earth's nonrotating reference frame
C****   VEQLON = longitude of Greenwich Meridion in Earth's nonrotating
C****            reference frame at vernal equinox
C****   ROTATE = change in longitude in Earth's nonrotating reference
C****            frame from point's location on vernal equinox to its
C****            current location where point is fixed on rotating Earth
C****   SLMEAN = longitude of fictitious mean Sun in Earth's rotating
C****            reference frame (normal longitude and latitude)
C****
C**** Output: DIST = distance to Sun in units of semi major axis
C****         SIND = sine of declination angle = sin(SUNLAT)
C****         COSD = cosine of the declination angle = cos(SUNLAT)
C****       SUNLON = longitude of point on Earth directly beneath Sun
C****       SUNLAT = latitude of point on Earth directly beneath Sun
C****       EQTIME = Equation of Time =
C****              = longitude of fictitious mean Sun minus SUNLON
C****
C**** From the above reference:
C**** (4-54): [1 - ECCEN*cos(EA)]*[1 + ECCEN*cos(TA)] = (1 - ECCEN^2)
C**** (4-55): tan(TA/2) = sqrt[(1+ECCEN)/(1-ECCEN)]*tan(EA/2)
C**** Yield:  tan(EA) = sin(TA)*sqrt(1-ECCEN^2) / [cos(TA) + ECCEN]
C****    or:  tan(TA) = sin(EA)*sqrt(1-ECCEN^2) / [cos(EA) - ECCEN]
C****
      IMPLICIT REAL*8 (A-H,M-Z)
      PARAMETER (TWOPI=6.283185307179586477d0,
     *           EDAYzY=365.2425d0, VE200D=79.3125)
C****
C**** Determine EAofVE from geometry: tan(EA) = b*sin(TA) / [e+cos(TA)]
C**** Determine MAofVE from Kepler's equation: MA = EA - e*sin(EA)
C**** Determine MA knowing time from vernal equinox to current day
C****
      BSEMI  = SQRT (1. - ECCEN*ECCEN)
      TAofVE = - OMEGVP
      EAofVE = ATAN2 (BSEMI*SIN(TAofVE), ECCEN+COS(TAofVE))
      MAofVE = EAofVE - ECCEN*SIN(EAofVE)
C     PERIHE = VE200D - MAofVE*EDAYzY/TWOPI
      MA     = MODULO (TWOPI*(DAY-VE200D)/EDAYzY + MAofVE, TWOPI)
C****
C**** Numerically invert Kepler's equation: MA = EA - e*sin(EA)
C****
      EA  = MA + ECCEN*(SIN(MA) + ECCEN*SIN(2.*MA)/2.)
   10 dEA = (MA - EA + ECCEN*SIN(EA)) / (1. - ECCEN*COS(EA))
      EA  = EA + dEA
      IF(ABS(dEA).gt.1.d-10)  GO TO 10
C****
C**** Calculate distance to Sun and true anomaly
C****
      DIST  = 1. - ECCEN*COS(EA)
      TA    = ATAN2 (BSEMI*SIN(EA), COS(EA)-ECCEN)
C****
C**** Change reference frame to be nonrotating reference frame, angles
C**** fixed according to stars, with Earth at center and positive x
C**** axis be ray from Earth to Sun were Earth at vernal equinox, and
C**** x-y plane be Earth's equatorial plane.  Distance from current Sun
C**** to this x axis is DIST sin(TA-TAofVE).  At vernal equinox, Sun is
C**** located at (DIST,0,0).  At other times, Sun is located at:
C****
C**** SUN = (DIST cos(TA-TAofVE),
C****        DIST sin(TA-TAofVE) cos(OBLIQ),
C****        DIST sin(TA-TAofVE) sin(OBLIQ))
C****
      SIND   = SIN(TA-TAofVE) * SIN(OBLIQ)
      COSD   = SQRT (1. - SIND*SIND)
      SUNX   = COS(TA-TAofVE)
      SUNY   = SIN(TA-TAofVE) * COS(OBLIQ)
      SLNORO = ATAN2 (SUNY,SUNX)
C****
C**** Determine Sun location in Earth's rotating reference frame
C**** (normal longitude and latitude)
C****
      VEQLON = TWOPI*VE200D - TWOPI/2. + MAofVE - TAofVE  !  modulo 2*Pi
      ROTATE = TWOPI*(DAY-VE200D)*(EDAYzY+1.)/EDAYzY
      SUNLON = MODULO (SLNORO-ROTATE-VEQLON, TWOPI)
               IF(SUNLON.gt.TWOPI/2.)  SUNLON = SUNLON - TWOPI
      SUNLAT = ASIN (SIN(TA-TAofVE)*SIN(OBLIQ))
C****
C**** Determine longitude of fictitious mean Sun
C**** Calculate Equation of Time
C****
      SLMEAN = TWOPI/2. - TWOPI*(DAY-FLOOR(DAY))
      EQTIME = MODULO (SLMEAN-SUNLON, TWOPI)
               IF(EQTIME.gt.TWOPI/2.)  EQTIME = EQTIME - TWOPI
C****
      RETURN
      END

      FUNCTION QLEAPY (JYEAR)
C****
C**** Determine whether the given JYEAR is a Leap Year or not.
C****
      LOGICAL*4 QLEAPY
      QLEAPY = .false.
      QLEAPY = QLEAPY .or.  MOD(JYEAR,  4).eq.0
      QLEAPY = QLEAPY .and. MOD(JYEAR,100).ne.0
      QLEAPY = QLEAPY .or.  MOD(JYEAR,400).eq.0
      RETURN
      END

      SUBROUTINE YMDtoD (JYEAR,JMONTH,DATE, DAY)
C****
C**** For a given JYEAR (A.D.), JMONTH and DATE (between 0. and 31.),
C**** calculate number of DAYs measured from 2000 January 1, hour 0.
C****
      IMPLICIT REAL*8 (A-H,O-Z)
      INTEGER*4 JDSUMN(12),JDSUML(12)
      PARAMETER (JDAY4C = 365*400 + 97, !  number of days in 4 centuries
     *           JDAY1C = 365*100 + 24, !  number of days in 1 century
     *           JDAY4Y = 365*  4 +  1, !  number of days in 4 years
     *           JDAY1Y = 365)          !  number of days in 1 year
      DATA JDSUMN /0,31,59, 90,120,151, 181,212,243, 273,304,334/
      DATA JDSUML /0,31,60, 91,121,152, 182,213,244, 274,305,335/
C****
      N4CENT = FLOOR((JYEAR-2000.d0)/400)
      IYR4C  = JYEAR-2000 - N4CENT*400
      N1CENT = IYR4C/100
      IYR1C  = IYR4C - N1CENT*100
      N4YEAR = IYR1C/4
      IYR4Y  = IYR1C - N4YEAR*4
      N1YEAR = IYR4Y
      DAY    = N4CENT*JDAY4C

      IF(N1CENT.gt.0)  GO TO 10
C**** First of every fourth century: 16??, 20??, 24??, etc.
      DAY = DAY + N4YEAR*JDAY4Y
      IF(N1YEAR.gt.0)  GO TO 200
      GO TO 100
C**** Second to fourth of every fourth century: 21??, 22??, 23??, etc.
   10 DAY = DAY + JDAY1C+1 + (N1CENT-1)*JDAY1C
      IF(N4YEAR.gt.0)  GO TO 20
C**** First four years of every second to fourth century when there is
C**** no leap year during the four years: 2100-2103, 2200-2203, etc.
      DAY = DAY + N1YEAR*JDAY1Y
      GO TO 210
C**** Subsequent four years of every second to fourth century when
C**** there is a leap year: 2104-2107, 2108-2111 ... 2204-2207, etc.
   20 DAY = DAY + JDAY4Y-1 + (N4YEAR-1)*JDAY4Y
      IF(N1YEAR.gt.0)  GO TO 200
C****
C**** Current year is a leap year
C****
  100 DAY = DAY + JDSUML(JMONTH) + DATE
      RETURN
C****
C**** Current year is not a leap frog year
C****
  200 DAY = DAY + JDAY1Y+1 + (N1YEAR-1)*JDAY1Y
  210 DAY = DAY + JDSUMN(JMONTH) + DATE
      RETURN
      END

      SUBROUTINE DtoYMD (DAY, JYEAR,JMONTH,DATE)
C****
C**** For a given DAY measured from 2000 January 1, hour 0, determine
C**** the JYEAR (A.D.), JMONTH and DATE (between 0. and 31.).
C****
      IMPLICIT REAL*8 (A-H,O-Z)
      INTEGER*4 JDSUMN(12),JDSUML(12)
      INTEGER*8 N4CENT
      PARAMETER (JDAY4C = 365*400 + 97, !  number of days in 4 centuries
     *           JDAY1C = 365*100 + 24, !  number of days in 1 century
     *           JDAY4Y = 365*  4 +  1, !  number of days in 4 years
     *           JDAY1Y = 365)          !  number of days in 1 year
      DATA JDSUMN /0,31,59, 90,120,151, 181,212,243, 273,304,334/
      DATA JDSUML /0,31,60, 91,121,152, 182,213,244, 274,305,335/
C****
      N4CENT = FLOOR(DAY/JDAY4C)
      DAY4C  = DAY - N4CENT*JDAY4C
      N1CENT = (DAY4C-1)/JDAY1C
      IF(N1CENT.gt.0)  GO TO 10
C**** First of every fourth century: 16??, 20??, 24??, etc.
      DAY1C  = DAY4C
      N4YEAR = DAY1C/JDAY4Y
      DAY4Y  = DAY1C - N4YEAR*JDAY4Y
      N1YEAR = (DAY4Y-1)/JDAY1Y
      IF(N1YEAR.gt.0)  GO TO 200
      GO TO 100
C**** Second to fourth of every fourth century: 21??, 22??, 23??, etc.
   10 DAY1C  = DAY4C - N1CENT*JDAY1C - 1
      N4YEAR = (DAY1C+1)/JDAY4Y
      IF(N4YEAR.gt.0)  GO TO 20
C**** First four years of every second to fourth century when there is
C**** no leap year: 2100-2103, 2200-2203, 2300-2303, etc.
      DAY4Y  = DAY1C
      N1YEAR = DAY4Y/JDAY1Y
      DAY1Y  = DAY4Y - N1YEAR*JDAY1Y
      GO TO 210
C**** Subsequent four years of every second to fourth century when
C**** there is a leap year: 2104-2107, 2108-2111 ... 2204-2207, etc.
   20 DAY4Y  = DAY1C - N4YEAR*JDAY4Y + 1
      N1YEAR = (DAY4Y-1)/JDAY1Y
      IF(N1YEAR.gt.0)  GO TO 200
C****
C**** Current year is a leap frog year
C****
  100 DAY1Y = DAY4Y
      DO 120 M=1,11
  120 IF(DAY1Y.lt.JDSUML(M+1))  GO TO 130
C     M=12
  130 JYEAR  = 2000 + N4CENT*400 + N1CENT*100 + N4YEAR*4 + N1YEAR
      JMONTH = M
      DATE   = DAY1Y - JDSUML(M)
      RETURN
C****
C**** Current year is not a leap frog year
C****
  200 DAY1Y  = DAY4Y - N1YEAR*JDAY1Y - 1
  210 DO 220 M=1,11
  220 IF(DAY1Y.lt.JDSUMN(M+1))  GO TO 230
C     M=12
  230 JYEAR  = 2000 + N4CENT*400 + N1CENT*100 + N4YEAR*4 + N1YEAR
      JMONTH = M
      DATE   = DAY1Y - JDSUMN(M)
      RETURN
      END

      FUNCTION VERNAL (JYEAR)
C****
C**** For a given year, VERNAL calculates an approximate time of vernal
C**** equinox in days measured from 2000 January 1, hour 0.
C****
C**** VERNAL assumes that vernal equinoxes from one year to the next
C**** are separated by exactly 365.2425 days, a tropical year
C**** [Explanatory Supplement to The Astronomical Ephemeris].  If the
C**** tropical year is 365.2422 days, as indicated by other references,
C**** then the time of the vernal equinox will be off by 2.88 hours in
C**** 400 years.
C****
C**** Time of vernal equinox for year 2000 A.D. is March 20, 7:36 GMT
C**** [NASA Reference Publication 1349, Oct. 1994].  VERNAL assumes
C**** that vernal equinox for year 2000 will be on March 20, 7:30, or
C**** 79.3125 days from 2000 January 1, hour 0.  Vernal equinoxes for
C**** other years returned by VERNAL are also measured in days from
C**** 2000 January 1, hour 0.  79.3125 = 31 + 29 + 19 + 7.5/24.
C****
      IMPLICIT REAL*8 (A-H,O-Z)
      PARAMETER (EDAYzY=365.2425d0, VE2000=79.3125)
      VERNAL = VE2000 + (JYEAR-2000)*EDAYzY
      RETURN
      END

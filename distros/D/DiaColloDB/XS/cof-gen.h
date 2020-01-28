//-*- Mode: C++ -*-
#ifndef DIACOLLO_COF_GEN_H
#define DIACOLLO_COF_GEN_H

#include "utils.h"
#include <omp.h>      //-- OpenMP

//======================================================================
// default types

typedef uint64_t DefaultTermIdT;
typedef uint16_t DefaultDateT;
typedef uint64_t DefaultFreqT;

//======================================================================
// default constants

const size_t DMAX_DEFAULT = 5;


//======================================================================
// debug

//#define T2C_MR_DEBUG 1
#if T2C_MR_DEBUG
# define MRDEBUG(x) x
#else
# define MRDEBUG(x)
#endif

//======================================================================
// buffering

//-- T2C_GEN_BUFSIZE : number of co-occurrence records to buffer in memory before writing
#ifdef T2C_GEN_BUFSIZE
const size_t MaxBufSize = T2C_GEN_BUFSIZE;
#else
//const size_t MaxBufSize = 0; //-- no buffering
//const size_t MaxBufSize = (1<<10); //-- 1K
const size_t MaxBufSize = (1<<12); //-- 4K
//const size_t MaxBufSize = (1<<13); //-- 8K
//const size_t MaxBufSize = (1<<16); //-- 64K ("should be enough ...")
#endif


//======================================================================
// CofGenerator: top-level template struct
template<typename TermIdT=uint64_t,typename DateT=uint16_t,typename FreqT=uint64_t>
struct CofGenerator {
    //======================================================================
    // atomic constants
    static const TermIdT EOS = (TermIdT)-1;

    //======================================================================
    // atomic data
    const char *prog;
    const char *ifile;
    const char *ofile;
    FILE       *ifp;
    FILE       *ofp;
    size_t      dmax;
    omp_lock_t output_lock;

    //======================================================================
    // constructors etc.
    CofGenerator(const char *prog_="CofGenerator", size_t dmax_=DMAX_DEFAULT)
        : prog(prog_), ifile(NULL), ofile(NULL), ifp(NULL), ofp(NULL), dmax(dmax_)
    {
        omp_init_lock(&output_lock);
    };

    ~CofGenerator()
    {
        close();
        omp_destroy_lock(&output_lock);
    };

    void close()
    {
        if (ifp && ifp != stdin) { fclose(ifp); ifp=NULL; }
        if (ofp && ofp != stdout) { fclose(ofp); ofp=NULL; }
        ifile = NULL;
        ofile = NULL;
    };


    //======================================================================
    // struct CofGenerator::WordT
    struct __attribute__((__packed__)) WordT {
        TermIdT tid;
        DateT   date;
        
        WordT()
            : tid(0), date(0)
        {};

        WordT(TermIdT tid_, DateT date_)
            : tid(tid_), date(date_)
        {};

        WordT(const WordT& w)
            : tid(w.tid), date(w.date)
        {};

        inline void decode()
        {
            tid  = binval(tid);
            date = binval(date);
        };

        inline bool eos() const
        { return tid == EOS; };

        inline bool operator<(const WordT& w) const
        { return tid < w.tid || (tid==w.tid && date < w.date); };
    
        inline bool operator<=(const WordT& w) const
        { return tid < w.tid || (tid==w.tid && date <= w.date); };
    
        inline bool operator==(const WordT& w) const
        { return tid==w.tid && date==w.date; };
    };
    
    //======================================================================
    // common typedefs
    typedef pair<WordT,WordT> WordPairT;
    typedef vector<WordT>     SentenceT;
    typedef map<WordPairT, FreqT>  MapT;

    typedef vector<WordPairT> WordPairBufferT;
    
    //======================================================================
    // worker struct
    struct WorkerT {
        CofGenerator *gen;

        int  thrid;
        const char *ifile;
        FILE *fin;
        FILE *fout;

        char *linebuf;
        char *datebuf;

        size_t linelen;
        size_t lineno;
        ssize_t nread;

        WordT     w;
        SentenceT sent;
        WordPairBufferT pbuf;

        WorkerT(CofGenerator *gen_, int thrid_, FILE *fin_, FILE *fout_)
            : gen(gen_), thrid(thrid_), fin(fin_), fout(fout_),
              linebuf(NULL), datebuf(NULL),
              linelen(0),lineno(0),nread(0)
        {};

        ~WorkerT()
        {
            if (fin && fin != stdin) { fclose(fin); fin=NULL; }
            //if (fout && fout != stdout) { fclose(fout); fout=NULL; }
            if (linebuf) { free(linebuf); linebuf=NULL; }
        };

        void SkipSentence()
        {
            int c,prev=EOF;
            while (!feof(fin)) {
                c = fgetc(fin);
                if (c==EOF) return;
                if (prev=='\n' && c=='\n') break;
                prev = c;
            }
        };

        inline bool GetToken()
        {
            nread = getline(&linebuf,&linelen,fin);
            if (nread <= 0) {
                if (!feof(fin))
                    throw runtime_error(Format("error reading from %s: %s\n", gen->ifile, strerror(errno)));
                return false;
            }
            if (linebuf[0] == '\n') {
                //-- blank line: EOS
                w.tid = EOS;
            }
            else {
                //-- normal token
                w.tid  = strtoul(linebuf,  &datebuf,  0);
                w.date = strtoul(datebuf,  NULL,      0);
            }
            return true;
        };

        void flushBuffer()
        {
            omp_set_lock(&(gen->output_lock));
            for (typename WordPairBufferT::const_iterator bi=pbuf.begin(); bi != pbuf.end(); ++bi) {
                fprintf(fout, "%zu\t%zu\t%zu\t%zu\n",
                        (size_t)bi->first.tid,
                        (size_t)bi->first.date,
                        (size_t)bi->second.tid,
                        (size_t)bi->second.date);
            }
            omp_unset_lock(&(gen->output_lock));
            pbuf.clear();
        };
    
        void addSentence()
        {
            if (sent.size() < 2) return;
            typename SentenceT::const_iterator si,sj, s_begin=sent.begin(), s_end=sent.end();
        
            for (si=s_begin; si != s_end; ++si) {
                for (sj=max(si-gen->dmax, s_begin); sj < si; ++sj) {
                    pbuf.push_back( std::make_pair(*si,*sj) );
                }
                for (sj=si+1; sj != min(si+gen->dmax+1, s_end); ++sj) {
                    pbuf.push_back( std::make_pair(*si,*sj) );
                }
            }

            if (pbuf.size() >= MaxBufSize)
                flushBuffer();
        };
    };
    //--/WorkerT

    //======================================================================
    // worker callback
    void cbWorker(size_t inbytes)
    {
        //-- worker code goes here
        int thrid = omp_get_thread_num();
        int nthr  = omp_get_num_threads();

        //-- worker locals: open
        WorkerT worker(this, thrid, fopen(ifile, "r"), ofp);
        if (!worker.fin)
            throw runtime_error(Format("thread #%d open failed for %s: %s", thrid, ifile, strerror(errno)));

        long off_lo = thrid * (inbytes / nthr);
        long off_hi = (thrid == nthr-1) ? inbytes : (thrid+1) * (inbytes/nthr);
        MRDEBUG(fprintf(stderr, "%s[%d/%d] : range=%4zd - %4zd [FILE=%p]\n", prog, thrid,nthr, off_lo,off_hi, worker.fin));

        //-- worker guts: initialize; scan for next EOS
        fseek(worker.fin, off_lo, SEEK_SET);
        if (off_lo != 0) {
            worker.SkipSentence();
        }

        //-- worker guts: main loop
        while ( worker.GetToken() ) {
            if (worker.w.tid==EOS) {
                worker.addSentence();
                worker.sent.clear();
                //MRDEBUG(fprintf(stderr, "%s[%d/%d] : EOS at offset=%ld\n", prog, thrid,nthr, ftell(worker.fin)));
                if (ftell(worker.fin) >= off_hi) break;
            } else {
                worker.sent.push_back(worker.w);
            }
        }
        worker.addSentence();
        worker.sent.clear();
        worker.flushBuffer();
        MRDEBUG(fprintf(stderr, "%s[%d/%d] : worker done at off=%ld\n", prog, thrid,nthr, ftell(worker.fin)));
    
        //-- worker cleanup (in worker-destructor)
    };
    
    //======================================================================
    // guts
    int main(const char *ifile_, const char *ofile_="-", size_t dmax_=DMAX_DEFAULT)
    {
        close();
        ifile = ifile_;
        ofile = ofile_;
        dmax  = dmax_;

        if (!ifile || !*ifile || strcmp(ifile,"-")==0) {
            fprintf(stderr, "%s: INFILE must be seekable\n", prog);
            exit(1);
        } else if ( !(ifp = fopen(ifile,"r")) ) {
            fprintf(stderr, "%s: open failed for input file '%s': %s", prog, ifile, strerror(errno));
            exit(1);
        }
        if (!ofile || !*ofile || strcmp(ofile,"-")==0) {
            ofp = stdout;
        } else if ( !(ofp = fopen(ofile,"w")) ) {
            fprintf(stderr, "%s: open failed for output file '%s': %s", prog, ofile, strerror(errno));
            exit(2);
        }

        MRDEBUG(fprintf(stderr, "%s: %s -> %s (dmax=%zd)\n", prog, ifile, ofile, dmax));
        try {
            //-- get total input file size
            struct stat statbuf;
            if (fstat(fileno(ifp), &statbuf) != 0)
                throw std::runtime_error(Format("%s: fstat() failed for file '%s': %s", prog, ifile, strerror(errno)));
            size_t inbytes = statbuf.st_size;
            MRDEBUG(fprintf(stderr, "%s: nbytes=%zd\n", prog, inbytes));

            //-- OpenMP: parallelize
#pragma omp parallel
            {
                cbWorker(inbytes);               
            }

            //-- cleanup
            close();
        }
        catch (exception &e) {
            fprintf(stderr, "%s: EXCEPTION %s\n", prog, e.what());
            return -1;
        }

        return 0;
    };

};

#endif /* DIACOLLO_COF_GEN_H */

